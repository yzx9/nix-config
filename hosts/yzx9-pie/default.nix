inputs:

let
  inherit (import ../_shared.nix) user_yzx9 networkingLabWireless;
in
inputs.self.lib.mkNixosRpiConfiguration {
  config = {
    vars = {
      hostname = "yzx9-pie";
      type = "nixos";
      system = "aarch64-linux";
      user = user_yzx9;
    };

    purpose.gui = true;

    proxy.selfHost.enable = true;
  };

  host = {
    imports = [
      ./hardware-configuration.nix
      ./gnome.nix
    ];

    networking = networkingLabWireless // {
      wireless.enable = false;
    };
  };
}
