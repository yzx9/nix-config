{ inputs, lib, ... }:

{
  imports = [
    inputs.self.homeManagerModules.default

    ../modules/_shared/options.nix

    ./ai
    ./gui

    ./aim.nix
    ./apps.nix
    ./atuin.nix
    ./base.nix
    ./bat.nix
    ./btop.nix
    ./delta.nix
    ./fzf.nix
    ./gh.nix
    ./git.nix
    ./gopass.nix
    ./gpg.nix
    ./gradle.nix
    ./lazygit.nix
    ./nvim.nix
    ./shell.nix
    ./ssh.nix
    ./worktrunk.nix
    ./yazi.nix
  ];

  # See: ryantm/agenix#352
  launchd.agents.activate-agenix.config.KeepAlive.Crashed = lib.mkForce true;
}
