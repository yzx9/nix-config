let
  shared = import ../_shared.nix;
in
{
  vars = {
    hostname = "cvcd-gpu0";
    type = "home-manager";
    system = "x86_64-linux";
    user = shared.user_yzx9 // {
      name = "yzx";
    };
  };

  purpose = {
    daily = true;
  };
}
