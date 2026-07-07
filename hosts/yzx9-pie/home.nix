{ pkgs, ... }:

{
  home.packages = with pkgs; [
    vikunja-desktop
  ];

  programs.kitty = {
    themeFile = "Catppuccin-Latte";
  };
}
