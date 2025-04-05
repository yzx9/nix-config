{ inputs, ... }:

{
  imports = [
    ../../home
    ../_shared/nix-core.nix
    ./shell.nix

    inputs.agenix.homeManagerModules.default
  ];
}
