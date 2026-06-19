# Simple terminal UI for git
{
  programs.lazygit = {
    enable = true;

    settings = {
      git.overrideGpg = true;
    };
  };
}
