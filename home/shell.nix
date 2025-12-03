{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.shell = {
    # Disable globally shell integration for all supported shells.
    enableShellIntegration = false;

    # Enable individual shell integrations can be overridden with their respective option
    enableBashIntegration = config.programs.bash.enable;
    enableZshIntegration = config.programs.zsh.enable;
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

    # Workaround to make vi-mode work with atuin
    initContent = lib.optionalString config.programs.atuin.enable ''
      function zvm_after_init() {
        zvm_bindkey viins '^R' atuin-search
        zvm_bindkey vicmd '^R' atuin-search
      }
    '';
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

  programs.atuin = {
    enable = config.purpose.daily;

    forceOverwriteSettings = true; # NOTE: DANGER: This will overwrite any user settings on each activation

    flags = [ "--disable-up-arrow" ]; # or --disable-ctrl-r

    settings = {
      auto_sync = false; # TODO: Enable aync, maybe setup our own server?
      sync_frequency = "1h";
      sync_address = "https://api.atuin.sh";
      search_mode = "fuzzy";
      keymap_mode = "vim-insert";
    };
  };
}
