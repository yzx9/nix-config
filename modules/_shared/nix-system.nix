{ inputs, lib, ... }:

{
  # Custom NIX_PATH and flake registry
  # https://nixos-and-flakes.thiscute.world/best-practices/nix-path-and-flake-registry

  # Make `nix run nixpkgs#nixpkgs` use the same nixpkgs as the one used by
  # this flake. This is set automatically by nixpkgs.lib.nixosSystem, but we
  # need to override it here since we are using different nixpkgs for system
  # and application in some case (e.g. rpi)
  nixpkgs.flake.source = lib.mkForce inputs.nixpkgs;

  # remove nix-channel related tools & configs, we use flakes instead.
  nix.channel.enable = false;

  # but NIX_PATH is still used by many useful tools, so we set it to the same
  # value as the one used by this flake. Make `nix repl '<nixpkgs>'` use the
  # same nixpkgs as the one used by this flake.
  environment.etc."nix/inputs/nixpkgs".source = "${inputs.nixpkgs}";

  # Add this flake to the NIX_PATH, so that `nix repl '<this-flake>'` works.
  nix.registry.yzx9.to = {
    type = "path";
    path = "${../../.}";
  };
}
