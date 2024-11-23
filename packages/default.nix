{ pkgs, ... }@inputs:

let
  nixvim = import ./nixvim inputs;
in
nixvim
// {
  kanboard = pkgs.callPackage ./kanboard/package.nix { };
  macism = pkgs.callPackage ./macism { };
  vaa3d-x = pkgs.callPackage ./vaa3d-x { };
}
