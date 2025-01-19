{
  system,
  nixpkgs,
  nixvim,
  ...
}:

let
  pkgs = nixpkgs.legacyPackages.${system};
in
{
  git-conventional-commits = pkgs.callPackage ./git-conventional-commits { };

  macism = pkgs.callPackage ./macism { };

  nixvim = import ./nixvim {
    inherit pkgs;
    nixvim = nixvim.legacyPackages.${system};
  };

  vaa3d-x = pkgs.callPackage ./vaa3d-x { };
}
