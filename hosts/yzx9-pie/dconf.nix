{ pkgs, ... }:

{
  dconf = {
    enable = true;

    settings = {
      "org/gnome/desktop/interface" = {
        gtk-im-module = "";
        enable-animations = false;
        color-scheme = "prefer-light";
        text-scaling-factor = 1.25;
      };

      "org/gnome/desktop/a11y/applications" = {
        screen-keyboard-enabled = true;
      };

      "org/gnome/shell" = {
        disable-user-extensions = false;

        enabled-extensions = with pkgs.gnomeExtensions; [
          keep-awake.extensionUuid
        ];
      };

      "mobi/phosh/osk" = {
        ignore-hw-keyboards = false;
        ignore-activation = "[]";
      };
    };
  };
}
