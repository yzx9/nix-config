{ config, ... }:

{
  age.secrets."radicale-auth" = {
    file = ../../secrets/radicale-auth.age;
    owner = "radicale";
    group = config.users.users.radicale.group;
  };

  services.radicale = {
    enable = true;

    settings = {
      server.hosts = [ "127.0.0.1:5232" ];

      auth = {
        type = "htpasswd";
        htpasswd_filename = config.age.secrets."radicale-auth".path;
        htpasswd_encryption = "plain";
      };

      storage.filesystem_folder = "/var/lib/radicale/collections";
    };
  };
}
