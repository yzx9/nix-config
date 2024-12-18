inputs:

let
  inherit (import ../_lib.nix inputs) mkNixosConfiguration;
  inherit (import ../_shared.nix) user_yzx9;
in
mkNixosConfiguration {
  vars = {
    hostname = "yzx9-ws";
    type = "nixos";
    system = "x86_64-linux";
    user = user_yzx9;
  };

  purpose = {
    daily = true;
  };

  proxy.enable = true;
  nvidia.enable = true;
  docker = {
    enable = true;
    rootless = false;
  };
}
