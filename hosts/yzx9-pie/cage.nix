{ config, pkgs, ... }:

{
  services.cage = {
    enable = true;
    user = config.my.user.name;

    program = pkgs.writeShellScript "firefox-kiosk" ''
      export MOZ_ENABLE_WAYLAND=1
      export GDK_BACKEND=wayland

      exec ${pkgs.firefox}/bin/firefox \
        --kiosk \
        "http://10.6.141.235:15932"
    '';
  };
}
