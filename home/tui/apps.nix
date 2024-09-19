{ pkgs, ... }:

{
  home.packages = with pkgs; [
    neofetch
  ];

  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
}
