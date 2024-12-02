{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ncurses
    bat
    tree
    btop
    neofetch
  ];

  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
}
