{ config, pkgs, ... }:

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
    # connect to the Docker daemon socket". NOTE: docker group membership is
    # equivalent to root — acceptable here because this user is dedicated to a
    # single repo's runner and nothing else.
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
      http_proxy = config.my.proxy.http;
      https_proxy = config.my.proxy.http;
      no_proxy = "127.0.0.1,localhost,::1";
    };
  };
}
