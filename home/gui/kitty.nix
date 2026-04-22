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
  (lib.mkIf config.purpose.gui {
    programs.kitty = {
      enable = true;
      themeFile = "Catppuccin-Mocha";
    };
    home.shellAliases.s = "kitten ssh";
  })

  # only configure kitty in daily used host
  (lib.mkIf config.purpose.daily {
    programs.kitty = {
      font = {
        name = "FiraCode Nerd Font";
        package = pkgs.nerd-fonts.fira-code;
        size = 13;
      };

      settings = {
        hide_window_decorations = if pkgs.stdenvNoCC.hostPlatform.isDarwin then "titlebar-only" else "yes";
        window_margin_width = 5;
        background_opacity = 0.9;

        tab_title_template = "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{tab.last_focused_progress_percent}{custom}{title}";

        # NOTE: disabling the read confirmation is this akes a security risk
        clipboard_control = "write-clipboard write-primary read-clipboard read-primary";

        macos_show_window_title_in = "window";
        macos_option_as_alt = true;
        macos_quit_when_last_window_closed = true;
      };
    };

    xdg.configFile."kitty/tab_bar.py".source = ./kitty_tab_bar.py;
  })
]
