{
  inputs,
  vars,
  pkgs,
  lib,
  ...
}:

{
  # Flake
  # enable flakes globally
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Custom NIX_PATH and flake registry
  # https://nixos-and-flakes.thiscute.world/best-practices/nix-path-and-flake-registry

  # make `nix run nixpkgs#nixpkgs` use the same nixpkgs as the one used by this flake.
  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  nix.channel.enable = false; # remove nix-channel related tools & configs, we use flakes instead.

  # but NIX_PATH is still used by many useful tools, so we set it to the same value as the one used by this flake.
  # Make `nix repl '<nixpkgs>'` use the same nixpkgs as the one used by this flake.
  environment.etc."nix/inputs/nixpkgs".source = "${inputs.nixpkgs}";

  # TODO: remove in next bump
  # https://github.com/NixOS/nix/issues/9574
  nix.settings.nix-path = lib.mkForce "nixpkgs=/etc/nix/inputs/nixpkgs";

  nix.settings = {
    # substituers that will be considered before the official ones (https://cache.nixos.org)
    substituters = [
      # "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://nix-community.cachix.org"
    ];

    trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];

    builders-use-substitutes = true;

    trusted-users = [ vars.user.name ];
  };

  # Auto upgrade nix package and the daemon service.
  nix.package = pkgs.nix;

  # do garbage collection weekly to keep disk usage low
  nix.gc = {
    automatic = lib.mkDefault true;
    options = lib.mkDefault "--delete-older-than 7d";
  };
}
