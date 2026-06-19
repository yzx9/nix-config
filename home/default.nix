{ inputs, lib, ... }:

{
  imports = [
    inputs.self.homeManagerModules.default

    ../modules/_shared/options.nix

    ./ai
    ./gui

    ./apps.nix
    ./atuin.nix
    ./base.nix
    ./bat.nix
    ./btop.nix
    ./delta.nix
    ./gh.nix
    ./git.nix
    ./gopass.nix
    ./gpg.nix
    ./gradle.nix
    ./lazygit.nix
    ./nvim.nix
    ./pim.nix
    ./shell.nix
    ./ssh.nix
    ./worktrunk.nix
    ./yazi.nix
  ];

  # See: ryantm/agenix#352
  launchd.agents.activate-agenix.config.KeepAlive.Crashed = lib.mkForce true;
}
