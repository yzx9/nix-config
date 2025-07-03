{ inputs, pkgs, ... }:

{
  imports = [
    inputs.agenix.homeManagerModules.default

    {
      home.packages = [
        pkgs.kitty.terminfo # always install kitty terminfo
      ];

      programs.zsh.completionInit = "autoload -U compinit && compinit -u";
    }

    ../../home
    ../_shared/overlays
    ../_shared/nix-core.nix
  ];
}
