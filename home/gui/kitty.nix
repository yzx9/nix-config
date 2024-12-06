{
  config,
  pkgs,
  lib,
  ...
}:

let
  purpose = config.purpose;
in
{
  config =
    (lib.mkIf purpose.gui {
      programs.kitty = {
        enable = true;
        font = {
          name = "FiraCode Nerd Font";
        };
        extraConfig = ''
          background_opacity 0.75
          macos_show_window_title_in window

          # Note that disabling the read confirmation is this akes a security risk
          clipboard_control write-clipboard write-primary read-clipboard read-primary
        '';
      };

      home.shellAliases.s = "kitten ssh";
    })
    // {
      home.packages = [ pkgs.kitty.terminfo ];
    };
}
