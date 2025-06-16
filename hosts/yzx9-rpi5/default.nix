inputs:

let
  inherit (import ../../modules/_shared/lib.nix inputs) mkNixosRpiConfiguration;
  inherit (import ../_shared.nix) user_yzx9;
in
mkNixosRpiConfiguration {
  config = {
    vars = {
      hostname = "yzx9-rpi5";
      type = "nixos";
      system = "aarch64-linux";
      user = user_yzx9;
    };

    proxy.selfHost = {
      enable = true;
      public = true;
    };
  };

  host = {
    imports = [
      ./backup.nix
      ./frpc.nix
      ./hardware-configuration.nix
      ./networking.nix
      ./rss.nix
    ];
  };
}
