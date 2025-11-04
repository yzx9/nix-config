{
  config,
  pkgs,
  lib,
  ...
}:

lib.mkIf config.purpose.gui {
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    # It is sometimes useful to fine-tune packages
    nerd-fonts.fira-code

    cascadia-code # Includes Cascadia Code NF

    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];
}
