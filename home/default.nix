{ lib, ... }:

{
  imports = [
    ../modules/_shared/options.nix

    ./gui

    ./ai.nix
    ./apps.nix
    ./base.nix
    ./bat.nix
    ./btop.nix
    ./delta.nix
    ./git.nix
    ./gpg.nix
    ./nvim.nix
    ./pim.nix
    ./shell.nix
    ./ssh.nix
    ./yazi.nix
  ];

  launchd.agents.activate-agenix.config.KeepAlive.Crashed = lib.mkForce true;
}
