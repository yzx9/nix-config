# Kitty terminal configuration
#
# NOTE: If you want to remove kitty, you should also remove `kitty.terminfo` in `modules/_shared/app.nix`

{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin;
in
lib.mkMerge [
  (lib.mkIf config.my.host.gui {
    programs.kitty = {
      enable = true;
    };
    home.shellAliases.s = "kitten ssh";
  })

  # only configure kitty in daily used host
  (lib.mkIf config.my.host.daily {
    programs.kitty = {
      themeFile = "Catppuccin-Mocha";

      font = {
        name = "FiraCode Nerd Font";
        package = pkgs.nerd-fonts.fira-code;
        size = 13;
      };

      settings = {
        hide_window_decorations = if isDarwin then "titlebar-only" else "yes";
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

  (lib.mkIf (isDarwin && config.programs.firefox.enable) {
    # NOTE: On macOS the firefox binary lives inside the .app bundle, so the
    # path must include the `Contents/` (plural) directory. A common mistake
    # is to write `Content/` (singular) or to omit the `Applications/Firefox.app`
    # prefix — both result in a non-existent path and links silently fail to open.
    programs.kitty.settings.open_url_with = "${config.programs.firefox.package}/Applications/Firefox.app/Contents/MacOS/firefox";
  })
]
