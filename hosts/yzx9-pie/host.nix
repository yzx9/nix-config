{ lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # networking
  networking = {
    networkmanager.enable = lib.mkForce false; # we have to disable it since webgitkit cache-missing

    nameservers = [ "1.1.1.1" "8.8.8.8" ];

    wireless = {
      # Enables wireless support via wpa_supplicant.
      enable = true;
      networks = {
        chn = {
          pskRaw = "935490cd011d5c6af8fa1b12a2fce67437d6fcc800daf278b0e6342ca3e97374";
        };
      };
    };
  };
}
