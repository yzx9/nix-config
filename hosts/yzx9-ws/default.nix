inputs:

let
  inherit (import ../_shared/lib.nix inputs) mkNixosConfiguration;
  inherit (import ../_shared/user.nix) user_yzx9;
in
mkNixosConfiguration {
  config = {
    vars = {
      hostname = "yzx9-ws";
      type = "nixos";
      system = "x86_64-linux";
      user = user_yzx9;
    };

    purpose = {
      daily = true;
    };

    proxy.selfHost.enable = true;
    nvidia.enable = true;
    docker = {
      enable = true;
      rootless = false;
    };
  };

  host = {
    imports = [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix

      ./xorg.nix
    ];
  };
}
