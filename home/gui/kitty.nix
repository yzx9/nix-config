# Kitty terminal configuration
#
# NOTE: If you want to remove kitty, you should also remove `kitty.terminfo` in
#    `modules/_shared/app.nix`

{
  config,
  pkgs,
  lib,
  ...
}:

lib.mkIf config.purpose.gui {
  programs.kitty = {
    enable = true;

    font = {
      name = "FiraCode Nerd Font";
      package = pkgs.nerd-fonts.fira-code;
      size = 13;
    };

    shellIntegration = {
      enableBashIntegration = true;
      enableZshIntegration = true;
    };

    # only configure kitty in daily used host
    settings = lib.mkIf config.purpose.daily {
      hide_window_decorations = if pkgs.stdenvNoCC.hostPlatform.isDarwin then "titlebar-only" else "yes";
      window_margin_width = 5;
      background_opacity = 0.75;
      macos_show_window_title_in = "window";

      # NOTE: disabling the read confirmation is this akes a security risk
      clipboard_control = "write-clipboard write-primary read-clipboard read-primary";
    };
  };

  home.shellAliases.s = "kitten ssh";
}
