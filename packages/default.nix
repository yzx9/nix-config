{
  self,
  nixpkgs,
  aim,
  nixvim,
  ...
}:

system:

let
  pkgs = nixpkgs.legacyPackages.${system}.extend self.overlays.default;

  catppuccin-bat = pkgs.callPackage ./catppuccin-bat { };

  nixvim' = import ./nixvim {
    inherit pkgs;
    nixvim = nixvim.legacyPackages.${system};
  };
in
{
  inherit catppuccin-bat;
  catppuccin-yazi-flavor = pkgs.callPackage ./catppuccin-yazi-flavor { inherit catppuccin-bat; };

  aim = aim.packages.${system}.aim;

  nixvim = nixvim';
  nixvim-lsp = nixvim'.extend { lsp.enable = true; };

  pmp-library = pkgs.callPackage ./pmp-library { };

  vaa3d-x = pkgs.callPackage ./vaa3d-x { };
}
