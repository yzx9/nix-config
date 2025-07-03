{ inputs, ... }:

{
  imports = [
    inputs.agenix.nixosModules.default
    inputs.home-manager.nixosModules.home-manager

    ../_shared/overlays
    ../_shared/apps.nix
    ../_shared/options.nix
    ../_shared/nix-core.nix
    ../_shared/nix-system.nix

    ./docker.nix
    ./networking.nix
    ./nvidia.nix
    ./system.nix

    ./modules/frpc.nix
  ];
}
