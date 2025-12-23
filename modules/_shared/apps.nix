##########################################################################
#
#  Install all apps and packages here.
#
##########################################################################

{ pkgs, lib, ... }:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "claude-code" ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  #
  # The packages installed here are available to all users, and are reproducible across machines, and are rollbackable.
  # But on macOS, it's less stable than homebrew.
  #
  # Related Discussion: https://discourse.nixos.org/t/darwin-again/29331
  environment.systemPackages = with pkgs; [
    git # Required by nix
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.

    # system
    util-linux
    dosfstools # fat filesystem
    e2fsprogs # ext filesystem

    kitty.terminfo # always install kitty terminfo
  ];

  programs.zsh.enable = true;

  environment.variables.EDITOR = "vim";
}
