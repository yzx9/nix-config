inputs:

let
  inherit (import ../_shared.nix) user_yzx9;
in
inputs.self.lib.mkNixosRpiConfiguration {
  config.my = {
    hostname = "yzx9-pie";
    type = "nixos";
    system = "aarch64-linux";
    user = user_yzx9;

    host.gui = true;

    proxy.selfHost.enable = true;
  };

  host.imports = [
    ./hardware-configuration.nix
    ./phosh.nix
    ./vnc.nix
  ];

  home.imports = [
    ./dconf.nix
    ./home.nix
  ];
}
