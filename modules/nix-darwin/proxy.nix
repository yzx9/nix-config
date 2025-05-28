{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.proxy;
  pkg = pkgs.xray;
in
lib.mkIf cfg.selfHost.enable {
  age.secrets."xray.json".file = ../../secrets/xray.json.age;

  # run `launchctl kickstart -k system/org.nixos.xray`
  launchd.daemons.xray = {
    path = [ pkg ];

    serviceConfig = {
      ProgramArguments = [
        "${pkg}/bin/xray"
        "--config"
        config.age.secrets."xray.json".path
      ];
      RunAtLoad = true;
      KeepAlive = true;
      # StandardOutPath = "/var/lib/xray.out";
    };
  };
}
