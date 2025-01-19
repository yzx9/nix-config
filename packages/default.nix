{ system, nixpkgs, ... }@inputs:

let
  pkgs = nixpkgs.legacyPackages.${system};

  nixvim = import ./nixvim inputs;
in
{
  inherit (nixvim) nixvim nixvim-mini;
  git-conventional-commits = pkgs.callPackage ./git-conventional-commits { };
  macism = pkgs.callPackage ./macism { };
  vaa3d-x = pkgs.callPackage ./vaa3d-x { };
}
