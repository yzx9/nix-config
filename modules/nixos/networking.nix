{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.proxy;

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
lib.mkMerge [
  (lib.mkIf (cfg.httpProxy != null) {
    # Configure network proxy if necessary
    networking.proxy.default = cfg.httpProxy;
    networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  })

  (lib.mkIf cfg.selfHost.enable {
    age.secrets."xray.json" = {
      file = ../../secrets/xray.json.age;
      mode = "444"; # workaround with systemd dynamic user
    };

    services.xray = {
      enable = true;
      settingsFile = config.age.secrets."xray.json".path;
    };

    # https://xtls.github.io/config/features/env.html
    systemd.services.v2ray.environment.XRAY_LOCATION_ASSET = "${assets}/share";

    networking.firewall.allowedTCPPorts = lib.optionals cfg.selfHost.public [
      config.proxy.selfHost.httpProxyPublicPort
    ];
  })
]
