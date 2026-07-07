{ config, pkgs, ... }:

let
  port = 31793;
in
{
  age.secrets."vikunja-env".file = ../../secrets/vikunja-env.age;

  services.vikunja = {
    enable = true;
    frontendScheme = "http";
    frontendHostname = "localhost";
    inherit port;

    database.type = "sqlite";

    environmentFiles = [ config.age.secrets."vikunja-env".path ];

    settings = {
      services = {
        enableregistration = false;
        timezone = "Asia/Shanghai";
      };
    };
  };

  # ── Firewall: only allow 10.6.141.0/24 ───────────────────────────────
  networking.firewall = {
    extraCommands = ''
      iptables -A nixos-fw -p tcp --dport ${toString port} -s 10.6.141.0/24 -j nixos-fw-accept
    '';

    extraStopCommands = ''
      iptables -D nixos-fw -p tcp --dport ${toString port} -s 10.6.141.0/24 -j nixos-fw-accept 2>/dev/null || true
    '';
  };
}
