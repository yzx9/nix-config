{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.my.proxy;

  assets =
    with pkgs;
    symlinkJoin {
      name = "xray-assets";
      paths = [
        v2ray-geoip
        v2ray-domain-list-community
      ];
    };
in
lib.mkIf cfg.selfHost.enable {
  age.secrets."xray.json".file = ../../secrets/xray.json.age;

  # To restart service: `launchctl kickstart -k system/org.nixos.xray`
  launchd.daemons.xray = {
    path = [ pkgs.xray ];

    # use command or script will warp script with wait4path automatically
    command = "${lib.getExe pkgs.xray} --config ${config.age.secrets."xray.json".path}";

    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/var/log/xray.log";
      StandardErrorPath = "/var/log/xray.log";

      # https://xtls.github.io/config/features/env.html
      EnvironmentVariables.XRAY_LOCATION_ASSET = "${assets}/share/v2ray";
    };
  };
}
