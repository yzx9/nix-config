let
  git = {
    name = "Zexin Yuan";
    email = "git@yzx9.xyz";
  };
in
{
  user_yzx9 = {
    inherit git;
    name = "yzx9";
  };

  user_yzx = {
    inherit git;
    name = "yzx";
  };

  # networking
  networking_lab = {
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];

    # Enables wireless support via wpa_supplicant.
    wireless = {
      enable = true;

      # Generateo pskRaw: wpa_passphrase ESSID PSK
      networks = {
        intl.priority = 1;
        intl.pskRaw = "85d5113a402237920afd151ad550de19496de30d73e348f6ddde10943eaf47bb";
        chn.pskRaw = "935490cd011d5c6af8fa1b12a2fce67437d6fcc800daf278b0e6342ca3e97374";
      };
    };
  };
}
