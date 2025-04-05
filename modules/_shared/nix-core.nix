{
  config,
  pkgs,
  lib,
  ...
}:

{
  nix.enable = true;

  # Flake
  # enable flakes globally
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Nix
  nix.settings = {
    # substituers that will be considered before the official ones (https://cache.nixos.org)
    substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://nix-community.cachix.org"
      "https://cache.nixos.org"
    ];

    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];

    builders-use-substitutes = true;

    trusted-users = [
      "root"
      config.vars.user.name
    ];
  };

  # Auto upgrade nix package and the daemon service.
  nix.package = pkgs.nix;

  # do garbage collection weekly to keep disk usage low
  nix.gc = {
    automatic = lib.mkDefault true;
    options = lib.mkDefault "--delete-older-than 7d";
  };
}
