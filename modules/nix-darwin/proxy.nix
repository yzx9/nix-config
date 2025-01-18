{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.proxy;
in
lib.mkIf cfg.selfHost.enable {
  age.secrets."xray.json" = {
    file = ../../secrets/xray.json.age;
    mode = "444"; # workaround with launchd agents
  };

  launchd.agents.xray = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.xray}/bin/xray"
        "--config"
        config.age.secrets."xray.json".path
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/xray.out";
      StandardErrorPath = "/tmp/xray.err";
    };
  };
}
