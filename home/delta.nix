{
  config,
  lib,
  pkgs,
  ...
}:

let
  enable = config.purpose.daily;

  catppuccin = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "delta";
    rev = "74b47a345638a2f19b3e5bdb9d7e4984066f9ac7";
    hash = "sha256-NjqqB/BHqduiNWKeksiRZUMfjRUodJlsVu1yaEIZRsM=";
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
