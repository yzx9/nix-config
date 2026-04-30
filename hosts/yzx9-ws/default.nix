inputs:

let
  inherit (import ../_shared.nix) user_yzx9;

  hermes-agent = import ./hermes-agent.nix;
in
inputs.self.lib.mkNixosConfiguration {
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
    { ... }:
    {
      imports = [
        # Include the results of the hardware scan.
        ./hardware-configuration.nix

        ./networking.nix
        ./xorg.nix

        hermes-agent.host
      ];

      # enable binfmt QEMU
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
    };

  home.imports = [
    hermes-agent.home
  ];
}
