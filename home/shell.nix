{ pkgs, lib, ... }:

{
  home.shell = {
    # Disable globally shell integration for all supported shells.
    enableShellIntegration = false;

    # Enable individual shell integrations can be overridden with their respective option
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };

  programs.bash.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    plugins = [
      {
        name = "vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
    ];
  };

  programs.nushell = {
    enable = true;

    settings = {
      buffer_editor = "vi";
      edit_mode = "vi";
      show_banner = false;

      # FIXME: https://github.com/nushell/nushell/issues/14650
      # Use cursor shapes to differentiate instead
      cursor_shape.vi_insert = "blink_line";
      cursor_shape.vi_normal = "blink_block";
    };

    environmentVariables = {
      # Disable prompt from Nushell Because it is duplicated with that of Starship
      PROMPT_INDICATOR_VI_NORMAL = "";
      PROMPT_INDICATOR_VI_INSERT = "";
    };

    extraConfig = "
      $env.config.keybindings ++= [
        {
          name: complete_hint_chunk
          modifier: shift
          keycode: right
          mode: [ emacs vi_normal vi_insert ]
          event: {
            until: [
              { send: historyhintwordcomplete }
              { edit: movewordright }
            ]
          }
        }
        {
          name: un_complete_hint_chunk
          modifier: shift
          keycode: left
          mode: [ emacs vi_normal vi_insert ]
          event: { edit: backspaceword }
        }
      ];
    ";
  };

  # A multi-shell multi-command argument completer
  programs.carapace.enable = true;

  # The minimal, blazing-fast, and infinitely customizable prompt for any shell!
  programs.starship = {
    enable = true;

    settings = lib.mkMerge [
      {
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
          vimcmd_symbol = "[:](subtext1)"; # For use with zsh-vi-mode
        };

        palette = "catppuccin_mocha";
      }

      (
        let
          catppuccin = pkgs.fetchFromGitHub {
            owner = "catppuccin";
            repo = "starship";
            rev = "e99ba6b210c0739af2a18094024ca0bdf4bb3225";
            hash = "sha256-1w0TJdQP5lb9jCrCmhPlSexf0PkAlcz8GBDEsRjPRns=";
          };
        in
        lib.importTOML "${catppuccin}/themes/mocha.toml"
      )
    ];
  };
}
