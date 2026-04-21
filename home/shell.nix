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

        gcloud.disabled = true;
      }

      (
        let
          catppuccin = pkgs.fetchFromGitHub {
            owner = "catppuccin";
            repo = "starship";
            rev = "5906cc369dd8207e063c0e6e2d27bd0c0b567cb8";
            hash = "sha256-FLHjbClpTqaK4n2qmepCPkb8rocaAo3qeV4Zp1hia0g=";
          };
        in
        lib.importTOML "${catppuccin}/themes/mocha.toml"
      )
    ];
  };
}
