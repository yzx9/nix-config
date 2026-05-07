let
  relayPort = 51185;
in
{
  # ── Relay server ──────────────────────────────────────────────────────
  services.paseo-relay = {
    enable = true;
    addr = "127.0.0.1";
    port = relayPort;
  };

  # ── Firewall: only allow 10.6.141.0/24 ───────────────────────────────
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p tcp --dport ${toString relayPort} -s 10.6.141.0/24 -j nixos-fw-accept
  '';

  networking.firewall.extraStopCommands = ''
    iptables -D nixos-fw -p tcp --dport ${toString relayPort} -s 10.6.141.0/24 -j nixos-fw-accept 2>/dev/null || true
  '';
}
