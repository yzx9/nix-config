let
  shared = import ../_shared.nix;
in
{
  vars = {
    hostname = "yzx9-mbp";
    type = "nix-darwin";
    system = "aarch64-darwin";
    user = shared.user_yzx9;
  };

  purpose = {
    daily = true;
    gui = true;
  };

  proxy.enable = true;
  docker.enable = true;
}
