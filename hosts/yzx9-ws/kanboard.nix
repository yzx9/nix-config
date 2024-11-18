{ pkgs, ... }:

let
  pkg = pkgs.callPackage ./kanboard/package.nix { };
  vhost = "kanboard";
in
{
  imports = [ ./kanboard/option.nix ];

  services.kanboard = {
    enable = true;
    package = pkg;
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
