inputs:

let
  inherit (import ../_lib.nix inputs) mkNixosConfiguration;
  dict = import ../_dict.nix;
in
mkNixosConfiguration {
  vars = {
    hostname = "yzx9-rpi5";
    type = "nixos";
    system = "aarch64-linux";
    user = dict.user_yzx9;
  };

  proxy.enable = true;
}
