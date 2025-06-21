{ pkgs, lib, ... }:

{
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
  programs.carapace = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  # The minimal, blazing-fast, and infinitely customizable prompt for any shell!
  programs.starship =
    let
      catppuccin = pkgs.fetchFromGitHub {
        owner = "catppuccin";
        repo = "starship";
        rev = "e99ba6b210c0739af2a18094024ca0bdf4bb3225";
        hash = "sha256-1w0TJdQP5lb9jCrCmhPlSexf0PkAlcz8GBDEsRjPRns=";
      };
    in
    {
      enable = true;

      enableBashIntegration = true;
      enableZshIntegration = true;

      settings = lib.mkMerge [
        {
          character = {
            success_symbol = "[›](bold green)";
            error_symbol = "[›](bold red)";
            vimcmd_symbol = "[❮](subtext1)"; # For use with zsh-vi-mode
          };

          palette = "catppuccin_mocha";
        }

        (lib.importTOML "${catppuccin}/themes/mocha.toml")
      ];
    };
}
