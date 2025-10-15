{ config, pkgs, ... }:

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
      mysqld.port = 42808;
    };
  };

  networking.firewall.allowedTCPPorts = [
    config.services.mysql.settings.mysqld.port
  ];
}
