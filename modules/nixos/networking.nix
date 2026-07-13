{
  config,
  lib,
  ...
}:

lib.mkMerge [
  (lib.mkIf (config.proxy.httpPublic != null) {
    # Configure network proxy if necessary
    networking.proxy.default = config.proxy.httpPublic;
    networking.proxy.noProxy = "10.1.0.0/16,10.152.183.0/24,127.0.0.1,localhost,internal.domain";
  })

  (lib.mkIf config.proxy.selfHost.enable {
    age.secrets.xray = {
      file = ../../secrets/xray.json.age;
      mode = "444"; # workaround with systemd dynamic user
    };

    services.xray = {
      enable = true;
      settingsFile = config.age.secrets.xray.path;
    };

    networking.firewall.allowedTCPPorts = lib.optionals config.proxy.selfHost.public [
      config.proxy.selfHost.httpPublicPort
    ];
  })
]
