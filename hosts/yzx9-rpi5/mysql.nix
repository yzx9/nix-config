{ config, pkgs, ... }:

let
  port = 42808;
in
{
  # NOTE: ## Upgrade
  # NixOS will not run `mysql_upgrade` automatically for you after upgrading
  # to a new major version, because it is a "dangerous" operation (can lead
  # to data corruption) and users are strongly advised (by MariaDB upstream)
  # to backup their database before running `mysql_upgrade`.
  # > mysqldump -u root -p --all-databases > alldb.sql
  # After backup is completed, you can proceed with the upgrade process
  # > mysql_upgrade
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;

    settings = {
      mysqld = {
        inherit port;
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
