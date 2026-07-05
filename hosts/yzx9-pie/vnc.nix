{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Remote view of the Phosh session over VNC (LAN only).
  #
  # wayvnc attaches to the running Wayland session via the wlr-screencopy
  # protocol, which phoc (Phosh's wlroots-based compositor) implements — so it
  # works under Phosh, unlike x11vnc/tigervnc which can only grab X11 and would
  # miss the Wayland desktop entirely.
  #
  # It must run *inside* the user's Wayland session, so this is a systemd user
  # unit rather than a system service. Phosh's session does not run
  # `systemctl --user import-environment WAYLAND_DISPLAY`, so we point wayvnc at
  # the socket explicitly via Environment= below.
  #
  # NOTE: this serves VNC with NO authentication — anyone on the same LAN can
  # view and control the phone. The firewall rule only limits exposure to the
  # LAN; it does not authenticate. Add `enable_auth=true` with a TLS cert (or
  # RSA key) plus a password — see wayvnc(1) — before relying on this on any
  # untrusted network. PAM won't work here: a user unit cannot read
  # /etc/shadow to validate system passwords.
  programs.wayvnc.enable = true;

  # Listen on all interfaces so any VNC viewer on the LAN can connect directly.
  networking.firewall.allowedTCPPorts = [ 5900 ];

  systemd.user.services.wayvnc = {
    description = "wayvnc VNC server for the Phosh session";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.wayvnc} 0.0.0.0";
      Environment = [
        "WAYLAND_DISPLAY=wayland-0"
        "XDG_RUNTIME_DIR=/run/user/%U"
      ];
      # Phosh takes a moment to come up; wayvnc will retry until the Wayland
      # socket appears.
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
