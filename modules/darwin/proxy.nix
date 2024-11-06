{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.proxy;
in
{
  config = lib.mkIf cfg.enable {
    age.secrets."xray.json".file = ../../secrets/xray.json.age;

    environment.systemPackages = [ pkgs.xray ];

    launchd.agents.xray = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.xray}/bin/xray"
          "--config"
          config.age.secrets."xray.json".path
        ];
        RunAtLoad = true;
        KeepAlive = true;
      };
    };
  };
}
