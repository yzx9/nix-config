{ nixvim, ... }:

pkgs: system:

let
  catppuccin-bat = pkgs.callPackage ./catppuccin-bat { };

  nixvim' = import ./nixvim {
    inherit pkgs;
    nixvim = nixvim.legacyPackages.${system};
  };
in
{
  inherit catppuccin-bat;
  catppuccin-yazi-flavor = pkgs.callPackage ./catppuccin-yazi-flavor { inherit catppuccin-bat; };

  gstack = pkgs.callPackage ./gstack { };

  hapi = pkgs.callPackage ./hapi { };

  nixvim = nixvim';
  nixvim-lsp = nixvim'.extend { lsp.enable = true; };

  pmp-library = pkgs.callPackage ./pmp-library { };

  vaa3d-x = pkgs.callPackage ./vaa3d-x { };

  with-secrets = pkgs.callPackage ./with-secrets { };

  zai-mcp-server = pkgs.callPackage ./zai-mcp-server { };

  zotero-mcp = pkgs.callPackage ./zotero-mcp { };
}
