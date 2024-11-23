{ pkgs, ... }:

{
  home.packages = with pkgs; [
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
