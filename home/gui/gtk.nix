# GTK theming settings
{ config, pkgs, ... }:

{
  gtk = {
    enable = config.my.host.gui;

    # Icon Theme
    # Required by inkscape, see: #228730
    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";

      # package = pkgs.kdePackages.breeze-icons;
      # name = "Breeze-Dark";
    };
  };
}
