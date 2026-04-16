{ config, ... }:

{
  services.hapi-hub = {
    enable = true;
    host = "0.0.0.0";
    port = 27872;
  };

  networking.firewall.allowedTCPPorts = [ 27872 ];
}
