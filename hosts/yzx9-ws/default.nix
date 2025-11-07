inputs:

let
  inherit (import ../../modules/_shared/lib.nix inputs) mkNixosConfiguration;
  inherit (import ../_shared.nix) user_yzx9 mkNetworkingLab;
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
      dev.enable = true;
    };

    proxy.selfHost.enable = true;
    nvidia.enable = true;
    docker = {
      enable = true;
      rootless = false;
    };
  };

  host =
    { lib, ... }:
    {
      imports = [
        # Include the results of the hardware scan.
        ./hardware-configuration.nix

        ./xorg.nix
      ];

      networking = lib.mkMerge [
        (mkNetworkingLab "enp2s0" "10.6.18.189")

        {
          firewall.allowedTCPPorts = [ 30202 ];
        }
      ];

      # enable binfmt QEMU
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
    };
}
