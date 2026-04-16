{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.programs.hapi-runner;
in
{
  options.programs.hapi-runner = {
    enable = lib.mkEnableOption "hapi runner";

    package = lib.mkPackageOption pkgs [ "yzx9" "hapi" ] { };

    hubUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "URL of the hub to connect to (HAPI_API_URL).";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.dataHome}/hapi";
      defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/.hapi"'';
      description = "Directory for hapi state (HAPI_HOME).";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = [ cfg.package ];
      }

      # ── Linux: systemd user service ────────────────────────────────────
      (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        systemd.user.services.hapi-runner = {
          Unit = {
            Description = "HAPI Runner (background agent session manager)";
            After = [ "network-online.target" ];
            Wants = [ "network-online.target" ];
          };

          Service = {
            Environment = [
              "HAPI_HOME=${cfg.dataDir}"
            ]
            ++ lib.optional (cfg.hubUrl != null) "HAPI_API_URL=${cfg.hubUrl}";

            ExecStart = "${lib.getExe' cfg.package "hapi"} runner start --foreground";

            Restart = "on-failure";
            RestartSec = 5;
            WorkingDirectory = cfg.dataDir;
          };

          Install.WantedBy = [ "default.target" ];
        };
      })

      # ── Darwin: launchd agent ──────────────────────────────────────────
      (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        launchd.agents.hapi-runner = {
          enable = true;
          config = {
            ProgramArguments = [
              "${lib.getExe' cfg.package "hapi"}"
              "runner"
              "start"
              "--foreground"
            ];
            RunAtLoad = true;
            KeepAlive = {
              SuccessfulExit = false;
            };
            ThrottleInterval = 5;
            WorkingDirectory = cfg.dataDir;
            EnvironmentVariables = {
              HAPI_HOME = cfg.dataDir;
            }
            // lib.optionalAttrs (cfg.hubUrl != null) {
              HAPI_API_URL = cfg.hubUrl;
            };
            StandardOutPath = "${cfg.dataDir}/logs/launchd-stdout.log";
            StandardErrorPath = "${cfg.dataDir}/logs/launchd-stderr.log";
            ProcessType = "Background";
          };
        };
      })
    ]
  );
}
