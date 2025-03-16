inputs:

let
  inherit (import ../_shared/lib.nix inputs) mkNixosConfiguration;
  inherit (import ../_shared/user.nix) user_yzx9;
in
mkNixosConfiguration {
  config = {
    vars = {
      hostname = "yzx9-rpi5";
      type = "nixos";
      system = "aarch64-linux";
      user = user_yzx9;
    };

    proxy.selfHost.enable = true;
  };

  host = {
    imports = [
      ./frpc.nix
      ./hardware-configuration.nix
      ./rss.nix
      ./networking.nix
      ./kanboard.nix
    ];
  };
}
