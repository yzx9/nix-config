inputs:

let
  inherit (import ../_shared.nix) user_yzx9 mkNetworkingLabWireless;
in
inputs.self.lib.mkNixosRpiConfiguration {
  config.my = {
    hostname = "yzx9-pie";
    type = "nixos";
    system = "aarch64-linux";
    user = user_yzx9;

    proxy.selfHost.enable = true;
  };

  host = {
    imports = [
      ./drm.nix
      ./hardware-configuration.nix
    ];

    networking = mkNetworkingLabWireless "wlan0" "10.6.141.236";
  };

  home.imports = [
    ./home.nix
  ];
}
