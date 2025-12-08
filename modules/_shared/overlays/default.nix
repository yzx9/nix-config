{ config, inputs, ... }:

{
  nixpkgs.overlays = [
    inputs.nur.overlays.default

    inputs.aim.overlays.default

    (_final: _prev: inputs.self.packages.${config.vars.system})

    (import ./goose.nix)

    (import ./vimPlugins.nix)
  ];
}
