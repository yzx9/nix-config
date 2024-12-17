{ system, nixpkgs, ... }@inputs:

let
  pkgs = nixpkgs.legacyPackages.${system};

  nixvim = import ./nixvim inputs;
in
{
  inherit (nixvim) nixvim nixvim-mini nixvim-formatters;
  macism = pkgs.callPackage ./macism { };
  vaa3d-x = pkgs.callPackage ./vaa3d-x { };
}
