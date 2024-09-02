{ pkgs, lib, ... }:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "Xcode.app" ];

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    nodejs
    corepack
    prettierd

    python312
    isort
    black

    cargo
    rustc
    rustfmt

    nixpkgs-review
    nixfmt-rfc-style

    go
    gotools

    yamllint
    yamlfmt

    shfmt
  ];

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };
}
