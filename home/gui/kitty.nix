# Kitty terminal configuration
#
# NOTE: If you want to remove kitty, you should also remove `kitty.terminfo` in `modules/_shared/app.nix`

{
  config,
  pkgs,
  lib,
  ...
}:

lib.mkMerge [
  {
    programs.kitty.enable = config.purpose.gui;
  }

  # only configure kitty in daily used host
  (lib.mkIf config.purpose.daily {
    programs.kitty = {
      themeFile = "Catppuccin-Mocha";

      font = {
        name = "FiraCode Nerd Font";
        package = pkgs.nerd-fonts.fira-code;
        size = 13;
      };

      settings = {
        hide_window_decorations = if pkgs.stdenvNoCC.hostPlatform.isDarwin then "titlebar-only" else "yes";
        window_margin_width = 5;
        background_opacity = 0.9;
        macos_show_window_title_in = "window";

        # NOTE: disabling the read confirmation is this akes a security risk
        clipboard_control = "write-clipboard write-primary read-clipboard read-primary";
      };
    };

    home.shellAliases.s = "kitten ssh";
  })
]
