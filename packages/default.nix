{
  self,
  nixpkgs,
  agenix,
  aim,
  ...
}:

system:

let
  lib = nixpkgs.lib;
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
}
# `nix flake check --all-systems` force-evaluates every exported package on
# every system. The SigNoz packages are Linux-only (meta.platforms), so only
# export them on Linux; elsewhere nixpkgs check-meta would refuse to evaluate.
// lib.optionalAttrs (lib.hasInfix "linux" system) {
  inherit (pkgs.yzx9)
    signoz
    signoz-otel-collector
    ;
}
// {
  # External packages
  agenix = agenix.packages.${system}.default;
  aim = aim.packages.${system}.aim;
}
