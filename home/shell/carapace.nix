{ ... }:

{
  # multi-shell multi-command argument completer
  programs.carapace = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };
}
