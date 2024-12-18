inputs:

let
  inherit (import ../_shared.nix inputs) mkDarwinConfiguration;
in
mkDarwinConfiguration (import ./config.nix)
