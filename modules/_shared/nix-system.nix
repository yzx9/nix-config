{ inputs, lib, ... }:

{
  # Custom NIX_PATH and flake registry
  # https://nixos-and-flakes.thiscute.world/best-practices/nix-path-and-flake-registry

  # make `nix run nixpkgs#nixpkgs` use the same nixpkgs as the one used by this flake.
  nix.registry.nixpkgs.flake = inputs.nixpkgs; # For flake commands
  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ]; # For legacy commands
  nix.channel.enable = false; # remove nix-channel related tools & configs, we use flakes instead.

  # but NIX_PATH is still used by many useful tools, so we set it to the same value as the one used by this flake.
  # Make `nix repl '<nixpkgs>'` use the same nixpkgs as the one used by this flake.
  environment.etc."nix/inputs/nixpkgs".source = "${inputs.nixpkgs}";
  # https://github.com/NixOS/nix/issues/9574
  nix.settings.nix-path = lib.mkForce "nixpkgs=/etc/nix/inputs/nixpkgs";

  # Add this flake to the NIX_PATH, so that `nix repl '<this-flake>'` works.
  nix.registry.yzx9.to = {
    type = "path";
    path = "${../../.}";
  };
}
