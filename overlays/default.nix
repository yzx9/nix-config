{ nixpkgs, ... }@inputs:

let
  aim = import ./aim.nix inputs;
  packages = import ./packages.nix inputs;
  nur = import ./nur.nix inputs;
in
{
  inherit
    aim
    packages
    nur
    ;

  default = nixpkgs.lib.composeManyExtensions [
    aim
    packages
    nur
  ];
}
