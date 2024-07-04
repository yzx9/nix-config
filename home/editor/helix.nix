{ pkgs, ... }:

{
  home.packages = with pkgs; [ tree-sitter ];

  programs.helix = {
    enable = true;
    settings = {
      theme = "autumn_night_transparent";
      editor.cursor-shape = {
        normal = "block";
        insert = "bar";
        select = "underline";
      };
      keys = {
        # auto switch IME between normal and insert mode
        normal = {
          esc = [
            "normal_mode"
            ":pipe-to bash ~/.config/helix/scripts/ime-switch.sh"
          ];
          i = [
            "insert_mode"
            ":pipe-to bash ~/.config/helix/scripts/ime-switch.sh 1"
          ];
          # use `li` or remap `after insert`
          I = [
            "insert_at_line_start"
            ":pipe-to bash ~/.config/helix/scripts/ime-switch.sh 1"
          ];
          a = [
            "move_char_right"
            "insert_mode"
            ":pipe-to bash ~/.config/helix/scripts/ime-switch.sh 1"
          ];
          A = [
            "insert_at_line_end"
            ":pipe-to bash ~/.config/helix/scripts/ime-switch.sh 1"
          ];
          o = [
            "open_below"
            ":pipe-to bash ~/.config/helix/scripts/ime-switch.sh 1"
          ];
          O = [
            "open_above"
            ":pipe-to bash ~/.config/helix/scripts/ime-switch.sh 1"
          ];
        };
        insert = {
          esc = [
            "normal_mode"
            ":pipe-to bash ~/.config/helix/scripts/ime-switch.sh"
          ];
        };
      };
    };
    themes = {
      autumn_night_transparent = {
        "inherits" = "autumn_night";
        "ui.background" = { };
      };
    };
  };

  home.file.".config/helix/scripts/ime-switch.sh".source = ../../scripts/ime_switch.sh;
}
