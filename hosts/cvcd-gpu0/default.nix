inputs:

let
  inherit (import ../_shared.nix inputs) mkHomeConfiguration;
in
mkHomeConfiguration (import ./config.nix)
