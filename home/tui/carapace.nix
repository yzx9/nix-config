{ ... }:

{
  # multi-shell multi-command argument completer
  programs.carapace = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
}
