{
  config,
  lib,
  ...
}:

lib.mkMerge [
  (lib.mkIf (config.my.proxy.httpPublic != null) {
    # Configure network proxy if necessary
    networking.proxy.default = config.my.proxy.httpPublic;
    networking.proxy.noProxy = "10.1.0.0/16,10.152.183.0/24,127.0.0.1,localhost,internal.domain";
  })

  (lib.mkIf config.my.proxy.selfHost.enable {
    age.secrets.xray.file = ../../secrets/xray.json.age;

    services.xray = {
      enable = true;
      settingsFile = config.age.secrets.xray.path;
    };

    networking.firewall.allowedTCPPorts = lib.optionals config.my.proxy.selfHost.public [
      config.my.proxy.selfHost.httpPublicPort
    ];

    systemd.services.xray.restartTriggers = [
      "${config.age.secrets.xray.file}"
    ];
  })
]
