{ config, pkgs, ... }:

{
  # PinePhone: https://nixos.wiki/wiki/PinePhone
  services.xserver = {
    enable = true;

    displayManager.lightdm.enable = false;

    desktopManager.phosh = {
      enable = true;
      user = config.vars.user.name;
      group = "users";
      # for better compatibility with x11 applications
      phocConfig.xwayland = "immediate";
    };
  };

  # Phosh forces `services.gnome.core-os-services.enable = true`, and the GNOME
  # module defaults `i18n.inputMethod.type = "ibus"` under that flag. The ibus
  # module then injects GTK_IM_MODULE/QT_IM_MODULE/XMODIFIERS=ibus into the
  # session, which routes GTK/libadwaita entry fields through IBus instead of
  # the Wayland text-input path and prevents Stevia from auto-activating.
  # Both upstream assignments use `mkDefault`, so a plain override wins.
  i18n.inputMethod.enable = false;

  environment.systemPackages = with pkgs; [
    phosh-mobile-settings
  ];

  # E-ink monitoring kiosk: never auto-suspend. Phosh's `enable-suspend`
  # gsetting only toggles the system-menu entry, not idle auto-suspend, so
  # block it at the logind / systemd level too.
  services.logind.settings.Login = {
    IdleAction = "ignore";
    HandlePowerKey = "ignore";
  };
  systemd.sleep.settings.Sleep = {
    AllowSuspend = "no";
    AllowHibernation = "no";
  };
}
