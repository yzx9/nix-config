{
  config,
  pkgs,
  lib,
  ...
}:

let
  # TODO: change to config
  btop =
    lib.optional config.nvidia.enable (pkgs.btop.override { cudaSupport = true; })
    ++ lib.optional (!config.nvidia.enable) pkgs.btop;
in
{
  home.packages =
    (with pkgs; [
      ncurses
      tree
      neofetch
    ])
    ++ lib.optionals config.purpose.daily (
      with pkgs;
      [
        asciiquarium
        cmatrix
        sl
      ]
    )
    ++ btop;

  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
}
