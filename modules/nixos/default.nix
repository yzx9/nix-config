{ inputs, ... }:

{
  imports = [
    inputs.self.nixosModules.default
    inputs.agenix.nixosModules.default
    inputs.home-manager.nixosModules.home-manager

    ../_shared/apps.nix
    ../_shared/nix.nix
    ../_shared/nix-registry.nix
    ../_shared/options.nix

    ./docker.nix
    ./networking.nix
    ./nvidia.nix
    ./system.nix
  ];
}
