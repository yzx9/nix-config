let
  dict = import ../_shared.nix;
in
{
  vars = {
    hostname = "cvcd-gpu0";
    type = "home-manager";
    system = "x86_64-linux";
    user = dict.user_yzx9 // {
      name = "yzx";
    };
  };

  purpose = {
    daily = true;
  };
}
