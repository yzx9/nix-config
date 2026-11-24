{
  host,
  count,
  workDirBase,
}:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (config.xdg) stateHome;
  runners = lib.genAttrs' (lib.range 1 count) (
    id:
    let
      key = "nex-${toString id}";
      name = "${host}-${key}";
    in
    lib.nameValuePair key {
      enable = true;
      url = "https://github.com/yzx9/nex";
      inherit name;
      workDir = "${workDirBase}/${name}";

      # From nex → Settings → Actions → Runners. Write a single line without a trailing newline.
      tokenFile = "${stateHome}/github-runners/nex-registration-token";
      tokenType = "registration";
      extraLabels = [ "nix" ];
      extraPackages = [ pkgs.nix ];
      extraEnvironment = {
        http_proxy = config.my.proxy.httpPublic;
        https_proxy = config.my.proxy.httpPublic;
        no_proxy = "localhost,127.0.0.1,::1";
        NIX_CONFIG = "experimental-features = nix-command flakes";
      };
    }
  );

  cleanup = pkgs.writeShellApplication {
    name = "nex-runner-workdir-cleanup";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      gawk
      jq
      procps
      systemd
      util-linux
    ];
    text = ''
      safe_workspace() {
        local work=$1 mount
        [[ -d $work && -O $work && $(realpath -e -- "$work") == "$work" ]] || return 1
        mount=$(findmnt -fnro TARGET --target "$work") || return 1
        [[ -n $mount && $mount != / ]] || return 1
        # Reject a mount at the workspace itself or anywhere beneath it.
        awk -v work="$work" '$5 == work || index($5, work "/") == 1 { exit 1 }' /proc/self/mountinfo
      }

      clean_if_idle() {
        local key=$1 work=$2 unit="github-runner-$1.service"
        local size status=0
        systemctl --user is-active --quiet "$unit" || return 0
        if ! safe_workspace "$work" || ! jq -e --arg work "$work" '(.workFolder // .WorkFolder) == $work' \
          ${lib.escapeShellArg "${stateHome}/github-runners"}/"$key/.runner" >/dev/null; then
          printf 'Skipping %s: workspace unavailable or registration not migrated\n' "$unit"
          return 0
        fi
        size=$(du -smx -- "$work" | cut -f1) || return 1
        (( size > 200 * 1024 )) || return 0

        # Like the WS timer, skip when busy. A job can still be assigned
        # between this check and stop. A Worker in either GPU instance is
        # enough to defer cleanup; do not guess which workspace it uses.
        pgrep -u "$UID" -f '[R]unner[.]Worker' >/dev/null || status=$?
        [[ $status == 1 ]] || return 0
        printf 'Cleaning %s (%s MiB)\n' "$work" "$size"
        systemctl --user stop "$unit" || return 1
        if safe_workspace "$work" && find "$work" -xdev -mindepth 1 -delete; then
          status=0
        fi
        systemctl --user start "$unit" || return 1
        return "$status"
      }

      failed=0
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          key: runner:
          "clean_if_idle ${
            lib.escapeShellArgs [
              key
              runner.workDir
            ]
          } || failed=1"
        ) runners
      )}
      exit "$failed"
    '';
  };
in
{
  services.github-runners = runners;

  systemd.user.services.nex-runner-workdir-cleanup = {
    Unit.Description = "Clean oversized Nex runner workspaces while idle";
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe cleanup;
    };
  };

  systemd.user.timers.nex-runner-workdir-cleanup = {
    Unit.Description = "Check Nex runner workspaces daily";
    Timer = {
      OnCalendar = "*-*-* 02:37:00";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
