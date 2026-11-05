{
  self,
  nixpkgs,
  agenix,
  aim,
  ...
}:

system:

let
  pkgs = import nixpkgs {
    inherit system;
    config = import ../modules/_shared/nixpkgs-config.nix;
    overlays = [ self.overlays.default ];
  };
in
{
  inherit (pkgs.yzx9)
    catppuccin-bat
    catppuccin-yazi-flavor
    gstack
    nixvim
    nixvim-lsp
    tavily-mcp
    ;

  # External packages
  agenix = agenix.packages.${system}.default;
  aim = aim.packages.${system}.aim;
}
