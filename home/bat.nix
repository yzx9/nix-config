{ pkgs, ... }:

{
  programs.bat = {
    enable = true;

    config.theme = "mocha";

    themes.mocha = {
      src = pkgs.yzx9.catppuccin-bat;
      file = "themes/Catppuccin Mocha.tmTheme";
    };
  };
}
