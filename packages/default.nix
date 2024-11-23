{ pkgs, ... }@inputs:

let
  nixvim = import ./nixvim inputs;
in
nixvim
// {
  vaa3d-x = pkgs.callPackage ./vaa3d-x { };
  macism = pkgs.callPackage ./macism { };
}
