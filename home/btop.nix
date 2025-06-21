# A monitor of resources
# Homepage: https://github.com/aristocratos/btop
{
  config,
  pkgs,
  lib,
  ...
}:

let
  catppuccin = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "btop";
    rev = "f437574b600f1c6d932627050b15ff5153b58fa3";
    hash = "sha256-mEGZwScVPWGu+Vbtddc/sJ+mNdD2kKienGZVUcTSl+c=";
  };
in
lib.mkIf config.purpose.dev.devops.enable {
  home.packages = [ pkgs.btop ];

  xdg.configFile = {
    "btop/btop.conf".text = ''
      color_theme = "catppuccin_mocha"
      theme_background = False
    '';

    "btop/themes/catppuccin_mocha.theme".source = "${catppuccin}/themes/catppuccin_mocha.theme";
  };
}
