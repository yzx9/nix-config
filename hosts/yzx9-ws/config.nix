let
  shared = import ../_shared.nix;
in
{
  vars = {
    hostname = "yzx9-ws";
    type = "nixos";
    system = "x86_64-linux";
    user = shared.user_yzx9;
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
