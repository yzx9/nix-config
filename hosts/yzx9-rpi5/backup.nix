{ config, pkgs, ... }:

{
  age.secrets.labAccount.file = ../../secrets/lab-account.age;

  environment.systemPackages = [
    pkgs.cifs-utils # samba
  ];

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
}
