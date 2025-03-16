{ lib, ... }:

{
  # networking
  networking = {
    networkmanager.enable = lib.mkForce false;

    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];

    # Enables wireless support via wpa_supplicant.
    wireless = {
      enable = true;
      networks = {
        chn.pskRaw = "935490cd011d5c6af8fa1b12a2fce67437d6fcc800daf278b0e6342ca3e97374";
      };
    };
  };
}
