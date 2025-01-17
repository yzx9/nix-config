{ config, lib, ... }:

let
  cfg = config.proxy;
in
{
  config =
    (lib.mkIf cfg.httpProxy {
      # Configure network proxy if necessary
      networking.proxy.default = cfg.httpProxy;
      networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
    })
    // (lib.mkIf cfg.selfHost.enable {
      age.secrets."xray.json" = {
        file = ../../secrets/xray.json.age;
        mode = "444"; # workaround with systemd dynamic user
      };

      services.xray = {
        enable = true;
        settingsFile = config.age.secrets."xray.json".path;
      };

      networking.firewall = lib.mkIf cfg.selfHost.public {
        allowedTCPPorts = [
          12345
          12346
        ];
      };
    });
}
