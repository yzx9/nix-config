inputs:

let
  inherit (import ../_lib.nix inputs) mkNixosConfiguration;
  dict = import ../_dict.nix.nix;
in
mkNixosConfiguration {
  vars = {
    hostname = "yzx9-ws";
    type = "nixos";
    system = "x86_64-linux";
    user = dict.user_yzx9;
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
