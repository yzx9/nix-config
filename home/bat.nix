{ pkgs, ... }:

{
  programs.bat = {
    enable = true;

    config.theme = "mocha";

    themes.mocha = {
      src = pkgs.catppuccin-bat;
      file = "themes/Catppuccin Mocha.tmTheme";
    };
  };
}
