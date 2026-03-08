{ lib, ... }:

{
  imports = [
    ../modules/_shared/options.nix

    ./ai
    ./gui

    ./apps.nix
    ./atuin.nix
    ./base.nix
    ./bat.nix
    ./btop.nix
    ./delta.nix
    ./git.nix
    ./gitmoji.nix
    ./gopass.nix
    ./gpg.nix
    ./nvim.nix
    ./pim.nix
    ./shell.nix
    ./ssh.nix
    ./yazi.nix
  ];

  # See: ryantm/agenix#352
  launchd.agents.activate-agenix.config.KeepAlive.Crashed = lib.mkForce true;
}
