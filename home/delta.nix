{
  config,
  lib,
  pkgs,
  ...
}:

let
  enable = config.my.host.daily;

  catppuccin = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "delta";
    rev = "011516f5d14f66b771b3e716f29c77231e008c74";
    hash = "sha256-lztkxX9O41YossvRzpR7tqxMhDNT1Efy2JvkCwtsiXQ=";
  };
in
{
  programs.delta = {
    inherit enable;

    enableGitIntegration = config.programs.git.enable;

    options = {
      features = "side-by-side catppuccin-mocha";
    };
  };

  programs.git.includes = lib.optionals enable [
    {
      path = "${catppuccin}/catppuccin.gitconfig";
    }
  ];
}
