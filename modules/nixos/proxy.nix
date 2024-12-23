{ config, lib, ... }:

let
  cfg = config.proxy;
in
{
  config = lib.mkIf cfg.enable {
    # Configure network proxy if necessary
    networking.proxy.default = "http://127.0.0.1:12345/";
    networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    age.secrets."xray.json" = {
      file = ../../secrets/xray.json.age;
      mode = "444"; # workaround with systemd dynamic user
    };

    services.xray = {
      enable = true;
      settingsFile = config.age.secrets."xray.json".path;
    };

    networking.firewall = lib.mkIf cfg.public {
      allowedTCPPorts = [ 12345 ];
    };
  };
}
