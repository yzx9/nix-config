# a command-line fuzzy finder

{
  programs.fzf = {
    enable = true;

    historyWidget.command = ""; # The history manager integration is sourced after fzf and owns Ctrl-R.
  };
}
