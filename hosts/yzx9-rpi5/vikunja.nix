{ config, pkgs, ... }:

let
  port = 31793;
in
{
  age.secrets."vikunja-env".file = ../../secrets/vikunja-env.age;

  services.vikunja = {
    enable = true;
    frontendScheme = "http";
    frontendHostname = "localhost";
    inherit port;

    database.type = "sqlite";

    environmentFiles = [ config.age.secrets."vikunja-env".path ];

    settings = {
      services = {
        enableregistration = false;
        timezone = "Asia/Shanghai";
      };
    };
  };

  systemd.services.vikunja.restartTriggers = [
    "${config.age.secrets."vikunja-env".file}"
  ];
}
