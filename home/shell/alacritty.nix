{ ... }:

{
  programs.alacritty = {
    enable = true;
    settings = {
      # https://alacritty.org/config-alacritty.html
      live_config_reload = true;
      shell = {
        program = "/bin/zsh";
        args = [
          "-l"
          "-c"
          # "nu --login --interactive" # Spawn a nushell in login mode via default shell
          "zellij"
        ];
      };

      window = {
        dimensions = {
          columns = 120;
          lines = 45;
        };

        padding = {
          x = 10;
          y = 15;
        };

        dynamic_padding = false;
        # startup_mode = "Maximized";
        opacity = 0.9;
        # decorations = "none"; # window decorations, none: no border and title bar, full: border and title bar
        dynamic_title = true;
        option_as_alt = "Both"; # fix alt on darwin
      };

      scrolling = {
        history = 2000;
        multiplier = 20;
      };

      font = {
        normal = {
          family = "FiraCode Nerd Font";
          style = "Regular";
        };

        bold = {
          family = "FiraCode Nerd Font";
          style = "Bold";
        };

        # italic = {
        #   family = "Hack";
        #   style = "Italic";
        # };

        # bold_italic = {
        #   family = "monospace";
        #   style = "Bold Italic";
        # };

        size = 16;
      };

      ## Glyph offset determines the locations of the glyphs within their cells with
      ## the default being at the bottom. Increasing `x` moves the glyph to the
      ## right, increasing `y` moves the glyph upward.
      # glyph_offset = {
      #   x = 0;
      #   y = 0;
      # };
    };
  };
}
