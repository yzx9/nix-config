inputs:

let
  inherit (import ../_shared.nix inputs) mkNixosConfiguration;
in
mkNixosConfiguration (import ./config.nix)
