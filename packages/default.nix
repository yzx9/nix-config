{
  self,
  nixpkgs,
  agenix,
  aim,
  ...
}@inputs:

system:

let
  callYzx9Packages = import ./callPackages.nix inputs;

  pkgs = nixpkgs.legacyPackages.${system}.extend self.overlays.default;
in
{
  inherit (callYzx9Packages pkgs)
    catppuccin-bat
    catppuccin-yazi-flavor
    gstack
    hapi
    nixvim
    nixvim-lsp
    zai-mcp-server
    zotero-mcp
    ;

  # External packages
  agenix = agenix.packages.${system}.default;
  aim = aim.packages.${system}.aim;
}
