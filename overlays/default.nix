{ nixpkgs, ... }:

let
  goose = import ./goose.nix;
in
{
  inherit goose;

  default = nixpkgs.lib.composeManyExtensions [
    goose
  ];
}
