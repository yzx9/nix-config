{ config, inputs, ... }:

{
  programs.bat = {
    enable = true;

    config.theme = "mocha";

    themes.mocha = {
      src = inputs.self.packages.${config.vars.system}.catppuccin-bat;
      file = "themes/Catppuccin Mocha.tmTheme";
    };
  };
}
