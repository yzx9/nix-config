{ ... }:

{
  imports = [
    ./alacritty.nix # terminal
    ./kitty.nix
    ./nushell.nix
    ./zellij.nix # terminal multiplexer
    ./zsh.nix
  ];
}
