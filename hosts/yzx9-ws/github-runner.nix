{
  config,
  pkgs,
  lib,
  ...
}:

let
  containerProxy = "http://172.17.0.1:${toString config.my.proxy.selfHost.httpPublicPort}";

  # A FILE, not a directory: it is symlinked into a writable config dir
  # below. DOCKER_CONFIG must not point at the store itself — `docker
  # build` makes buildx mkdir $DOCKER_CONFIG/buildx, which is EROFS there.
  runnerDockerConfig = pkgs.writeText "docker-client-config.json" (
    builtins.toJSON {
      proxies.default = {
        httpProxy = containerProxy;
        httpsProxy = containerProxy;

        noProxy = lib.join "," [
          "localhost"
          "127.0.0.1"
          "::1"
          "172.16.0.0/12"
          # The debian mirrors are exempted from the proxy: apt is the one
          # plain-HTTP, high-fanout consumer (~40 concurrent large downloads),
          # and the upstream is the only link in the chain that has ever failed —
          # under that load it intermittently drops the transfer mid-flight,
          # while apt retries nothing, so one dropped deb fails the whole
          # `apt-get install`. Direct Fastly peering measured 4+ MB/s over the
          # full 284 MB / 436-package desktop toolchain closure with zero
          # failures. If direct reachability ever degrades, remove these two
          # hosts again and the traffic goes back through the proxy.
          "deb.debian.org"
          "security.debian.org"
        ];
      };
    }
  );
in
{
  age.secrets.nex-runner-pat.file = ../../secrets/nex-runner-pat.age;

  # Dedicated, fixed user/group so the runner's workspace keeps stable ownership
  # across service restarts. The module defaults to `DynamicUser=true`, which
  # rotates the uid on every (re)start; combined with a persistent workDir that
  # leaves stale target/ files owned by the previous uid, cargo then hits
  # `Permission denied (os error 13)` writing target/debug/deps. The module does
  # not create the user itself, so define it here.
  users.users.github-runner = {
    isSystemUser = true;
    group = "github-runner";
    # Grant access to the host docker daemon socket (/var/run/docker.sock is
    # 0660 root:docker). Without this, the deploy-release workflow's
    # `docker load` / `docker compose` hit "permission denied while trying to
    # connect to the Docker daemon socket".
    #
    # NOTE: docker group membership is equivalent to root — acceptable here
    # because this user is dedicated to a single repo's runner and nothing else.
    extraGroups = [ "docker" ];
  };
  users.groups.github-runner = { };

  # Persistent workspace, off the volatile /run tmpfs default. The module
  # creates neither the user nor this directory, so materialise it with tmpfiles
  # owned by the runner user. Kept distinct from the StateDirectory
  # (/var/lib/github-runner/nex-1, credentials + _diag logs) so the module's
  # start-time `find -delete` on the workDir can't touch credentials.
  systemd.tmpfiles.rules = [
    "d /var/lib/github-runner/nex-1-work 0700 github-runner github-runner -"
    # Writable home for the docker client config: outside the wiped workDir
    # (the module's start-time find -delete would remove ~/.docker), with
    # config.json kept declarative as a symlink to a store file.
    "d /var/lib/github-runner/docker-cli-config 0755 github-runner github-runner -"
    "L+ /var/lib/github-runner/docker-cli-config/config.json - - - - ${runnerDockerConfig}"
  ];

  services.github-runners.nex-1 = {
    enable = true;
    url = "https://github.com/yzx9/nex";
    name = "yzx9-ws-nex-1";
    tokenFile = config.age.secrets.nex-runner-pat.path;
    extraLabels = [ "nixos" ];

    # Move the checkout workspace off /run (tmpfs, RAM-limited, wiped on stop)
    # and pin a fixed user/group (disables DynamicUser).
    workDir = "/var/lib/github-runner/nex-1-work";
    user = "github-runner";
    group = "github-runner";

    # The module's default service PATH is just bash/coreutils/git/gnutar/gzip/
    # nix — it deliberately excludes /run/current-system/sw/bin, so job steps
    # can't see the docker CLI (`docker: command not found`, exit 127, killed
    # deploy-release). Ship docker on the service PATH directly. docker 29 has
    # `compose` compiled into the main binary, so this single package covers
    # `docker load`, `docker tag`, and `docker compose` alike.
    extraPackages = [ pkgs.docker ];

    extraEnvironment = {
      # runner / workflow commands themselves use host-local proxy
      http_proxy = config.my.proxy.http;
      https_proxy = config.my.proxy.http;
      no_proxy = "127.0.0.1,localhost,::1";

      # docker CLI launched by this runner uses a dedicated client config.
      # Containers/builds get the HTTP public proxy from config.json.
      DOCKER_CONFIG = "/var/lib/github-runner/docker-cli-config";
    };
  };

  # Containers reach the host-side xray via the docker0 gateway
  # (172.17.0.1); its dedicated inbounds are loopback-only, so the public
  # inbound (httpPublicPort, listening on ::) is the one they can use — the
  # firewall is the only thing in the way. Scope: docker's private ranges
  # (every bridge, including compose's br-*) to that single port. The jump
  # is inserted at INPUT position 1 so it is evaluated before nixos-fw's
  # reject, regardless of module ordering.
  networking.firewall.extraCommands = ''
    ip46tables -N docker-to-proxy 2>/dev/null || true
    ip46tables -C INPUT -j docker-to-proxy 2>/dev/null || ip46tables -I INPUT 1 -j docker-to-proxy
    ip46tables -F docker-to-proxy
    ip46tables -A docker-to-proxy -s 172.16.0.0/12 -p tcp --dport ${toString config.my.proxy.selfHost.httpPublicPort} -j ACCEPT
  '';

  # The runner's unit runs with ProtectSystem=strict: the whole filesystem
  # is read-only to its processes except the paths explicitly granted
  # (BindPaths workDir, StateDirectory). The docker CLI config dir must be
  # writable — `docker build` makes buildx mkdir $DOCKER_CONFIG/buildx there.
  systemd.services."github-runner-nex-1".serviceConfig.ReadWritePaths = [
    "/var/lib/github-runner/docker-cli-config"
  ];

  # Daily workDir cleanup, gated on a 100 GiB size threshold. The upstream
  # module already wipes the workDir on every service start (ExecStartPre
  # `find -mindepth 1 -delete`), so cleanup = restart the service — but only
  # while idle: restarting with a job in flight would kill that job.
  # Runner.Worker exists only for the duration of a job, so its absence means
  # idle (a tiny race window remains if a job starts between the check and
  # the restart; that round is simply skipped and the daily timer retries the
  # next day, instead of waiting a full week as before).
  systemd.services.github-runner-nex-1-workdir-cleanup = {
    description = "Restart the idle github-runner nex-1 to wipe its workDir when it exceeds 100 GiB";
    after = [ "github-runner-nex-1.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.systemd}/bin/systemctl is-active --quiet github-runner-nex-1.service || exit 0
      size_mib=$(${pkgs.coreutils}/bin/du -sm /var/lib/github-runner/nex-1-work | ${pkgs.coreutils}/bin/cut -f1)
      echo "workDir at ''${size_mib} MiB"
      if (( size_mib <= 100 * 1024 )); then
        echo "workDir within 100 GiB, nothing to clean"
        exit 0
      fi
      if ${pkgs.procps}/bin/pgrep -u github-runner -f 'Runner.Worker' > /dev/null; then
        echo "job in flight (Runner.Worker running), skipping this round"
        exit 0
      fi
      echo "workDir over 100 GiB and runner idle, restarting to wipe workDir"
      ${pkgs.systemd}/bin/systemctl restart github-runner-nex-1.service
    '';
  };

  systemd.timers.github-runner-nex-1-workdir-cleanup = {
    wantedBy = [ "timers.target" ];
    # Daily at 04:37, clear of the daily nix-gc run at 03:15. Persistent so a
    # missed run (machine off) fires after boot — the idle guard above makes
    # that safe. The size threshold makes the frequent cadence cheap: most
    # days the script just checks `du` and exits.
    timerConfig = {
      OnCalendar = "*-*-* 04:37:00";
      Persistent = true;
    };
  };
}
