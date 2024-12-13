{
  vars,
  pkgs,
  lib,
  ...
}:

{
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
}
