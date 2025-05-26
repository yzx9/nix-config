{ inputs, ... }:

{
  imports = [
    inputs.agenix.homeManagerModules.default

    ../../home
    ../_shared/nix-core.nix
    ./shell.nix
  ];
}
