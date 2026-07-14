inputs:

let
  inherit (import ../_shared.nix) user_yzx9;
in
inputs.self.lib.mkNixosConfiguration {
  config.my = {
    hostname = "yzx9-ws";
    type = "nixos";
    system = "x86_64-linux";
    user = user_yzx9;

    host = {
      trusted = true;
      daily = true;
      dev.enable = true;
    };

    permittedInsecurePackages = [
      "olm-3.2.16"
    ];

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

      ./networking.nix
      ./xorg.nix
    ];

    # enable binfmt QEMU
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  home.imports = [
    ./hermes-agent.nix
  ];
}
