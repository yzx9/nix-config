{ pkgs, lib, ... }:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ ];

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    nodejs
    corepack

    python312

    cargo
    rustc

    nixpkgs-review
  ];

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };
}
