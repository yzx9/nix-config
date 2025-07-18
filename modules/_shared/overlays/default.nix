{ config, inputs, ... }:

{
  nixpkgs.overlays = [
    inputs.nur.overlays.default

    (_final: _prev: inputs.self.packages.${config.vars.system})
  ];
}
