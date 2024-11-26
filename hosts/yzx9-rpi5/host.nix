{ lib, ... }:

{
  imports = [ ./rpi5.nix ];

  # networking
  networking.networkmanager.enable = lib.mkForce false; # we have to disable it since webgitkit cache-missing
  networking.wireless = {
    # Enables wireless support via wpa_supplicant.
    enable = true;
    networks = {
      "chn" = {
        psk = "";
      };
    };
  };
}
