{ inputs, ... }:

{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim

    ./config
    ./plugins
    ./utils.nix 
  ];
}
