{ inputs, ... }:

{
  imports = [
    inputs.agenix.darwinModules.default
    inputs.home-manager.darwinModules.home-manager

    ../_shared/apps.nix
    ../_shared/nix.nix
    ../_shared/nix-registry.nix
    ../_shared/options.nix

    ./aerospace.nix
    ./docker.nix
    ./homebrew.nix
    ./networking.nix
    ./nix.nix
    ./system.nix
  ];
}
