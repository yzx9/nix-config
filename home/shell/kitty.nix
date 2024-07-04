{ pkgs,... }:

{
  programs.kitty = {
    enable = true;
    font = {
      name = "FiraCode Nerd Font";
    };
    settings = {
      shell = "zsh --login -c nu --login --interactive"; # Spawn a nushell in login mode via default shell
    };
  };
}
