{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.services.paseo-relay;
in
{
  options.services.paseo-relay = {
    enable = lib.mkEnableOption "Paseo relay server";

    package = lib.mkPackageOption pkgs [ "yzx9" "paseo-relay" ] { };

    addr = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Listen address (e.g. \"127.0.0.1\", \"0.0.0.0\").";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8411;
      description = "Listen port";
    };

    logFormat = lib.mkOption {
      type = lib.types.enum [
        "text"
        "json"
      ];
      default = "json";
      description = "Log format.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "paseo-relay";
      description = "User to run the relay service.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "paseo-relay";
      description = "Group for the relay service.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = lib.mkIf (cfg.user == "paseo-relay") {
      isSystemUser = true;
      group = cfg.group;
    };

    users.groups.${cfg.group} = lib.mkIf (cfg.group == "paseo-relay") { };

    systemd.services.paseo-relay = {
      description = "Paseo relay server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe cfg.package} --addr ${cfg.addr}:${toString cfg.port} --log-format ${cfg.logFormat}";
        User = cfg.user;
        Group = cfg.group;
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
