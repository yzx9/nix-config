{ inputs, ... }:

{
  imports = [
    inputs.agenix.darwinModules.default
    inputs.home-manager.darwinModules.home-manager

    ../_shared/apps.nix
    ../_shared/nix-core.nix
    ../_shared/nix-system.nix
    ../_shared/options.nix
    ../_shared/overlays.nix

    ./aerospace.nix
    ./docker.nix
    ./homebrew.nix
    ./networking.nix
    ./nix-core.nix
    ./system.nix
  ];
}
