inputs:

let
  inherit (import ../_shared.nix inputs) mkHomeConfiguration;
  dict = import ../_shared.nix;
in
mkHomeConfiguration {
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
