{ inputs, pkgs, ... }:

{
  imports = [
    inputs.agenix.homeManagerModules.default
    inputs.self.homeManagerModules.gstack

    {
      home.packages = [
        pkgs.kitty.terminfo # always install kitty terminfo
      ];

      programs.zsh.completionInit = "autoload -U compinit && compinit -u";
    }

    ../../home
    ../_shared/nix.nix
  ];
}
