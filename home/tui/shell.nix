{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (config) vars;
in
{
  programs.bash.enable = true;

  programs.zsh = {
    enable = true;

    enableCompletion = true;
    completionInit =
      lib.optionalString (vars.type != "home-manager") "autoload -U compinit && compinit"
      + lib.optionalString (vars.type == "home-manager") "autoload -U compinit && compinit -u";

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

  # multi-shell multi-command argument completer
  programs.carapace = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  # prompt
  programs.starship = {
    enable = true;

    enableBashIntegration = true;
    enableZshIntegration = true;

    settings = {
      character = {
        success_symbol = "[›](bold green)";
        error_symbol = "[›](bold red)";
      };
    };
  };
}