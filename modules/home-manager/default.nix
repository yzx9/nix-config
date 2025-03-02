{ inputs, ... }:

{
  imports = [
    ../../home

    inputs.agenix.homeManagerModules.default
  ];
}
