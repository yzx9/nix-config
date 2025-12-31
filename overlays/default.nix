{ nixpkgs, ... }@inputs:

let
  aim = import ./aim.nix inputs;
  goose-cli = import ./goose-cli.nix;
  packages = import ./packages.nix inputs;
  nur = import ./nur.nix inputs;
in
{
  inherit
    aim
    goose-cli
    packages
    nur
    ;

  default = nixpkgs.lib.composeManyExtensions [
    aim
    goose-cli
    packages
    nur
  ];
}
