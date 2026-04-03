{
  self,
  nixpkgs,
  nixvim,
  agenix,
  aim,
  ...
}:

system:

let
  pkgs = nixpkgs.legacyPackages.${system}.extend self.overlays.default;

  catppuccin-bat = pkgs.callPackage ./catppuccin-bat { };

  gstack = pkgs.callPackage ./gstack { };

  zai-mcp-server = pkgs.callPackage ./zai-mcp-server { };

  zotero-mcp = pkgs.callPackage ./zotero-mcp { };

  nixvim' = import ./nixvim {
    inherit pkgs;
    nixvim = nixvim.legacyPackages.${system};
  };
in
{
  inherit catppuccin-bat gstack zai-mcp-server zotero-mcp;
  catppuccin-yazi-flavor = pkgs.callPackage ./catppuccin-yazi-flavor { inherit catppuccin-bat; };

  nixvim = nixvim';
  nixvim-lsp = nixvim'.extend { lsp.enable = true; };

  pmp-library = pkgs.callPackage ./pmp-library { };

  vaa3d-x = pkgs.callPackage ./vaa3d-x { };

  with-secrets = pkgs.callPackage ./with-secrets { };

  # External packages
  agenix = agenix.packages.${system}.default;
  aim = aim.packages.${system}.aim;
}
