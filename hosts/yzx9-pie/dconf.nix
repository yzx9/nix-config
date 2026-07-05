{ lib, ... }:
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
        # uint32 key (type "u"); a bare Nix `0` is written as int32, which the
        # schema rejects, so GSettings falls back to the default (300s) and the
        # value never sticks across reboots. mkUint32 forces the right type.
        idle-delay = lib.hm.gvariant.mkUint32 0; # 0 = never go idle -> never blank
      };
      "org/gnome/desktop/screensaver" = {
        lock-enabled = false; # honored by phosh since "Separate Locking from Blanking"
        lock-delay = lib.hm.gvariant.mkUint32 0; # uint32, same reason as idle-delay
      };
      "sm/puri/phosh/lockscreen" = {
        require-unlock = false; # safety net: if a lock ever shows, no password
      };
    };
  };
}
