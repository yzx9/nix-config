{
  system,
  nixpkgs,
  nixvim,
  ...
}:

let
  pkgs = nixpkgs.legacyPackages.${system};

  nixvim' = import ./nixvim {
    inherit pkgs;
    nixvim = nixvim.legacyPackages.${system};
  };

  all_platforms = {
    nixvim = nixvim';

    nixvim-lsp = nixvim'.extend {
      lsp.enable = true;
    };
  };

  darwin = {
    macism = pkgs.callPackage ./macism { };

    vaa3d-x = pkgs.callPackage ./vaa3d-x { };
  };
in
if
  (builtins.elem system [
    "x86_64-darwin"
    "aarch64-darwin"
  ])
then
  darwin // all_platforms
else
  all_platforms
