{ nixpkgs, ... }@inputs:

let
  aim = import ./aim.nix inputs;
  inkscape = import ./inkscape.nix inputs;
  nur = import ./nur.nix inputs;
  packages = import ./packages.nix inputs;
in
{
  inherit
    aim
    inkscape
    nur
    packages
    ;

  default = nixpkgs.lib.composeManyExtensions [
    aim
    inkscape
    nur
    packages
  ];
}
