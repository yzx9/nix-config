let
  shared = import ../_shared.nix;
in
{
  vars = {
    hostname = "yzx9-rpi5";
    type = "nixos";
    system = "aarch64-linux";
    user = shared.user_yzx9;
  };

  proxy.enable = true;
}
