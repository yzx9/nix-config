{ pkgs, ... }:

{
  home.packages = with pkgs; [
    neofetch
    btop
  ];

  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
}
