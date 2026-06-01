{ config, ... }:

{
  age.secrets."readeck-env" = {
    file = ../../secrets/readeck-env.age;
  };

  services.readeck = {
    enable = true;
    environmentFile = config.age.secrets."readeck-env".path;
    settings.server.port = 45286;
  };

  networking.firewall.allowedTCPPorts = [ 45286 ];
}
