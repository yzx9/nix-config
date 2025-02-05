inputs:

let
  inherit (import ../_shared/lib.nix inputs) mkNixosConfiguration;
  inherit (import ../_shared/user.nix) user_yzx9;
in
mkNixosConfiguration {
  vars = {
    hostname = "yzx9-pie";
    type = "nixos";
    system = "aarch64-linux";
    user = user_yzx9;
  };

  purpose.gui = true;

  proxy.selfHost.enable = true;
}
