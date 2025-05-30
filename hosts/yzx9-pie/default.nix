inputs:

let
  inherit (import ../../modules/_shared/lib.nix inputs) mkNixosRpiConfiguration;
  inherit (import ../_shared.nix) user_yzx9 networking_lab;
in
mkNixosRpiConfiguration {
  config = {
    vars = {
      hostname = "yzx9-pie";
      type = "nixos";
      system = "aarch64-linux";
      user = user_yzx9;
    };

    purpose.gui = true;

    proxy.selfHost.enable = true;
  };

  host = {
    imports = [
      ./hardware-configuration.nix
      ./gnome.nix
    ];

    networking = networking_lab;
  };
}
