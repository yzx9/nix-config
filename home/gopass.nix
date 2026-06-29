# Gopass password manager configuration
{
  config,
  pkgs,
  lib,
  ...
}:

let
  enable = config.purpose.daily;
in
lib.mkMerge [
  {
    home.packages = lib.optionals enable [ pkgs.gopass ];

    xdg.configFile = lib.mkIf enable {
      "gopass/config".text = lib.generators.toGitINI {
        mounts.path = "${config.home.homeDirectory}/.local/share/gopass/stores/root";

        recipients = {
          check = true;
          hash = "6f65b0e43737ee1d6cb30fa6616f2b193b103fc0d8f86016975140d7fddbed8d";
        };

        age = {
          agent-enabled = true;
          agent-timeout = 3600;
        };

        show = {
          autoclip = true;
          safecontent = true;
        };
      };
    };

    programs.firefox.nativeMessagingHosts = lib.optionals enable [ pkgs.gopass-jsonapi ];
  }

  # ── Darwin: launchd agent for the gopass age agent ──────────────────
  # gopass otherwise spawns the agent on-demand, detached and unsupervised,
  # which is unreliable (no restart on crash, races the first decrypt, and a
  # stale socket after a crash blocks the next start). Running it under
  # launchd supervises it instead. The agent runs in the foreground, blocking
  # on its socket, which is exactly what launchd expects.
  (
    let

      # launchd has no ExecStartPre, so clear a stale socket (left behind by a
      # crashed agent) before starting. gopass only unlinks its socket on a
      # graceful shutdown, so without this a restart would fail to bind.
      startScript = pkgs.writeShellScript "gopass-age-agent-start" ''
        set -euo pipefail
        rm -f "${config.home.homeDirectory}/.run/gopass/gopass-age-agent.sock"
        exec ${lib.getExe pkgs.gopass} age agent start
      '';

    in
    lib.mkIf (enable && pkgs.stdenv.hostPlatform.isDarwin) {

      launchd.agents.gopass-age-agent = {
        enable = true;
        config = {
          ProgramArguments = [ "${startScript}" ];
          RunAtLoad = true;
          KeepAlive.SuccessfulExit = false;
          ThrottleInterval = 5;
          WorkingDirectory = config.home.homeDirectory;
          EnvironmentVariables = {
            # HOME must match the interactive shell so both resolve the agent
            # socket to ~/.run/gopass/gopass-age-agent.sock (GOPASS_HOMEDIR and
            # XDG_RUNTIME_DIR are intentionally unset).
            HOME = config.home.homeDirectory;
            PATH = lib.concatStringsSep ":" [
              "${config.home.profileDirectory}/bin"
              "/usr/bin"
              "/bin"
              "/usr/sbin"
              "/sbin"
              "/usr/local/bin"
            ];
          };
          StandardOutPath = "${config.xdg.dataHome}/gopass/age-agent-launchd.out.log";
          StandardErrorPath = "${config.xdg.dataHome}/gopass/age-agent-launchd.err.log";
          ProcessType = "Background";
        };
      };
    }
  )
]
