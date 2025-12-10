{ nixpkgs, ... }:

let
  goose-cli = import ./goose-cli.nix;
in
{
  inherit goose-cli;

  default = nixpkgs.lib.composeManyExtensions [
    goose-cli
  ];
}
