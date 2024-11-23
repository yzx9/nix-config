{ pkgs, ... }:

{
  vaa3d-x = pkgs.callPackage ./vaa3d-x/default.nix { };
  macism = pkgs.callPackage ./macism/default.nix { };
}
