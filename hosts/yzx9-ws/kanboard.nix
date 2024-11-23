{ self, vars, ... }:

let
  vhost = "kanboard";
in
{
  imports = [ ../../packages/kanboard/option.nix ];

  services.kanboard = {
    enable = true;
    package = self.packages.${vars.system}.kanboard;
    virtualHost = vhost;
  };

  services.nginx.virtualHosts.${vhost} = {
    listen = [
      {
        addr = "127.0.0.1";
        port = 4090;
      }
    ];
    # forceSSL = true;
  };
}
