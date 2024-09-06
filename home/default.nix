{ ... }:

{
  imports = [
    ../options.nix
    ./gui
    ./tui
    ./apps.nix
    ./base.nix
    ./dev.nix
    ./git.nix
    ./gpg.nix
    ./ssh.nix
  ];
}
