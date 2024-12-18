inputs:

let
  inherit (import ../_lib.nix inputs) mkNixosConfiguration;
  inherit (import ../_shared.nix) user_yzx9;
in
mkNixosConfiguration {
  vars = {
    hostname = "yzx9-rpi5";
    type = "nixos";
    system = "aarch64-linux";
    user = user_yzx9;
  };

  proxy.enable = true;
}
