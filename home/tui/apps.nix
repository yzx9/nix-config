{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages =
    (with pkgs; [
      ncurses
      tree
      btop
      neofetch
    ])
    ++ lib.optionals config.purpose.daily (
      with pkgs;
      [
        asciiquarium
        cmatrix
        sl
      ]
    );

  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
}
