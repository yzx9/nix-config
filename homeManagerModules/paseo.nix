{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.programs.paseo;
in
{
  options.programs.paseo = {
    enable = lib.mkEnableOption "Paseo, a self-hosted daemon for AI coding agents";

    package = lib.mkPackageOption pkgs [ "yzx9" "paseo" ] { };

    port = lib.mkOption {
      type = lib.types.port;
      default = 6767;
      description = "Port for the Paseo daemon to listen on.";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address for the Paseo daemon to bind to.";
    };

    hostnames = lib.mkOption {
      type = lib.types.either (lib.types.enum [ true ]) (lib.types.listOf lib.types.str);
      default = [ ];
      example = [
        ".example.com"
        "myhost.local"
      ];
      description = ''
        Hostnames the Paseo daemon accepts in the Host header (DNS rebinding protection).
        Set to `true` to allow any host (not recommended).
      '';
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.dataHome}/paseo";
      defaultText = lib.literalExpression ''"''${config.xdg.dataHome}/paseo"'';
      description = "Directory for Paseo state (PASEO_HOME).";
    };

    relay = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to enable the relay connection for remote access.";
      };

      endpoint = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "10.6.141.234:8411";
        description = "Relay address the daemon connects to.";
      };

      publicEndpoint = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Public relay address used in pairing URLs. Defaults to endpoint.";
      };

      useTls = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Use wss:// for the relay connection.";
      };
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Extra environment variables for the Paseo daemon.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      # ── Linux: systemd user service ────────────────────────────────────
      (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        systemd.user.services.paseo = {
          Unit = {
            Description = "Paseo - self-hosted daemon for AI coding agents";
            After = [ "network-online.target" ];
            Wants = [ "network-online.target" ];
          };

          Service = {
            Environment = [
              "NODE_ENV=production"
              "PASEO_HOME=${cfg.dataDir}"
              "PASEO_LISTEN=${cfg.listenAddress}:${toString cfg.port}"
            ]
            ++ lib.optional (cfg.hostnames == true) "PASEO_HOSTNAMES=true"
            ++ lib.optional (
              lib.isList cfg.hostnames && cfg.hostnames != [ ]
            ) "PASEO_HOSTNAMES=${lib.concatStringsSep "," cfg.hostnames}"
            ++ lib.optional (
              cfg.relay.enable && cfg.relay.endpoint != null
            ) "PASEO_RELAY_ENDPOINT=${cfg.relay.endpoint}"
            ++ lib.optional (
              cfg.relay.enable && cfg.relay.publicEndpoint != null
            ) "PASEO_RELAY_PUBLIC_ENDPOINT=${cfg.relay.publicEndpoint}"
            ++ lib.optional (cfg.relay.enable && cfg.relay.useTls) "PASEO_RELAY_USE_TLS=true"
            ++ lib.mapAttrsToList (k: v: "${k}=${v}") cfg.environment;

            ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${cfg.dataDir}";
            ExecStart =
              "${cfg.package}/bin/paseo daemon start"
              + " --foreground"
              + " --listen ${cfg.listenAddress}:${toString cfg.port}"
              + " --home ${cfg.dataDir}"
              + lib.optionalString (!cfg.relay.enable) " --no-relay";

            Restart = "on-failure";
            RestartSec = 5;
          };

          Install.WantedBy = [ "default.target" ];
        };
      })

      # ── Darwin: launchd agent ──────────────────────────────────────────
      (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        launchd.agents.paseo = {
          enable = true;
          config = {
            ProgramArguments = [
              "${cfg.package}/bin/paseo"
              "daemon"
              "start"
              "--foreground"
              "--listen"
              "${cfg.listenAddress}:${toString cfg.port}"
              "--home"
              cfg.dataDir
            ]
            ++ lib.optional (!cfg.relay.enable) "--no-relay";
            RunAtLoad = true;
            KeepAlive = {
              SuccessfulExit = false;
            };
            ThrottleInterval = 5;
            WorkingDirectory = cfg.dataDir;
            EnvironmentVariables = {
              NODE_ENV = "production";
              PASEO_HOME = cfg.dataDir;
              PASEO_LISTEN = "${cfg.listenAddress}:${toString cfg.port}";
            }
            // lib.optionalAttrs (cfg.hostnames == true) {
              PASEO_HOSTNAMES = "true";
            }
            // lib.optionalAttrs (lib.isList cfg.hostnames && cfg.hostnames != [ ]) {
              PASEO_HOSTNAMES = lib.concatStringsSep "," cfg.hostnames;
            }
            // lib.optionalAttrs (cfg.relay.enable && cfg.relay.endpoint != null) {
              PASEO_RELAY_ENDPOINT = cfg.relay.endpoint;
            }
            // lib.optionalAttrs (cfg.relay.enable && cfg.relay.publicEndpoint != null) {
              PASEO_RELAY_PUBLIC_ENDPOINT = cfg.relay.publicEndpoint;
            }
            // lib.optionalAttrs (cfg.relay.enable && cfg.relay.useTls) {
              PASEO_RELAY_USE_TLS = "true";
            }
            // cfg.environment;
            StandardOutPath = "${cfg.dataDir}/logs/launchd-stdout.log";
            StandardErrorPath = "${cfg.dataDir}/logs/launchd-stderr.log";
            ProcessType = "Background";
          };
        };
      })
    ]
  );
}
