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

      # E-ink monitoring kiosk: keep the displayed content static (which is
      # near-zero power on e-ink) by never blanking and never locking. Each
      # lock-screen appearance forces a full-screen redraw, so we suppress it.
      "org/gnome/desktop/session" = {
        idle-delay = 0; # 0 = never go idle -> never blank
      };
      "org/gnome/desktop/screensaver" = {
        lock-enabled = false; # honored by phosh since "Separate Locking from Blanking"
        lock-delay = 0;
      };
      "sm/puri/phosh/lockscreen" = {
        require-unlock = false; # safety net: if a lock ever shows, no password
      };
    };
  };
}
