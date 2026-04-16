{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.services.hapi-hub;
in
{
  options.services.hapi-hub = {
    enable = lib.mkEnableOption "hapi hub";

    package = lib.mkPackageOption pkgs "hapi" { };

    host = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Host address to listen on.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3006;
      description = "Port to listen on.";
    };

    publicUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Public URL for the hub (used for relay and external access).";
    };

    relay = lib.mkEnableOption "relay mode (WireGuard + TLS end-to-end encryption via relay.hapi.run)";

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/hapi";
      description = "Directory for hapi state (HAPI_HOME).";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.hapi = {
      isSystemUser = true;
      group = "hapi";
      home = cfg.dataDir;
      createHome = true;
    };
    users.groups.hapi = { };

    systemd.services.hapi-hub = {
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      description = "HAPI Hub (server + web UI)";

      environment =
        {
          HAPI_LISTEN_HOST = cfg.host;
          HAPI_LISTEN_PORT = toString cfg.port;
          HAPI_HOME = cfg.dataDir;
        }
        // lib.optionalAttrs (cfg.publicUrl != null) {
          HAPI_PUBLIC_URL = cfg.publicUrl;
        };

      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe' cfg.package "hapi"} hub${lib.optionalString cfg.relay " --relay"}";
        WorkingDirectory = cfg.dataDir;
        StateDirectory = "hapi";
        User = "hapi";
        Group = "hapi";

        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
