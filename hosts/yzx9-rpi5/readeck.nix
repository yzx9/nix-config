{ config, ... }:

{
  age.secrets."readeck-env".file = ../../secrets/readeck-env.age;

  services.readeck = {
    enable = true;

    environmentFile = config.age.secrets."readeck-env".path;

    settings = {
      main.log_level = "info";

      server = {
        host = "0.0.0.0";
        port = 45286;
      };
    };
  };
}
