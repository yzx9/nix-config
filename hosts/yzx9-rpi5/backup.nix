{ config, pkgs, ... }:

{
  age.secrets.labAccount.file = ../../secrets/lab-account.age;
  age.secrets.backupPassphrase.file = ../../secrets/backup-passphrase.age;

  environment.systemPackages = [ pkgs.cifs-utils ]; # samba

  # See: https://nixos.wiki/wiki/Samba
  fileSystems."/nas/home" = {
    device = "//10.6.18.165/home";
    fsType = "cifs";
    options = [
      # this line prevents hanging on network split
      "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s"
      "credentials=${config.age.secrets.labAccount.path}"
    ];
  };

  # How to test:
  # > sudo systemctl restart borgbackup-job-root
  # > sleep 10
  # > sudo borg list /path/to/repo
  # > sudo borg list /path/to/repo::archive
  services.borgbackup.jobs.root =
    let
      inherit (config.services) freshrss;
    in
    {
      repo = "/nas/home/backup";
      doInit = true;
      compression = "auto,lzma";
      startAt = "daily";

      encryption = {
        mode = "repokey";
        passCommand = "cat ${config.age.secrets.backupPassphrase.path}";
      };

      prune.keep = {
        within = "1d"; # Keep all archives from the last day
        daily = 7;
        weekly = 4;
        monthly = -1;  # Keep at least one archive for each month
      };

      readWritePaths = [
        freshrss.dataDir
      ];

      preHook = ''
        DATA_PATH=${freshrss.dataDir} ${freshrss.package}/cli/db-backup.php
      '';

      paths = [
        # See: https://freshrss.github.io/FreshRSS/en/admins/05_Backup.html
        freshrss.dataDir
      ];

      # See: https://borgbackup.readthedocs.io/en/stable/usage/help.html#borg-help-patterns
      exclude = [
        "${freshrss.dataDir}/cache"
        "${freshrss.dataDir}/users/*/db.sqlite"
      ];
    };
}
