{ inputs, ... }:

{
  imports = [
    inputs.agenix.darwinModules.default
    inputs.home-manager.darwinModules.home-manager

    ../_shared/overlays
    ../_shared/apps.nix
    ../_shared/options.nix
    ../_shared/nix-core.nix
    ../_shared/nix-system.nix

    ./aerospace.nix
    ./docker.nix
    ./homebrew.nix
    ./networking.nix
    ./nix-core.nix
    ./system.nix
  ];
}
