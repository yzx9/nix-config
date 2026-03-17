{ nixpkgs, ... }@inputs:

let
  inherit (nixpkgs) lib;

  overlays = {
    aim = import ./aim.nix inputs;
    claude-code = import ./claude-code inputs;
    inkscape = import ./inkscape.nix inputs;
    nur = import ./nur.nix inputs;
    packages = import ./packages.nix inputs;
  };
in
overlays
// {
  default = lib.composeManyExtensions (lib.attrValues overlays);
}
