inputs:

let
  inherit (import ../_lib.nix inputs) mkHomeConfiguration;
  inherit (import ../_shared.nix) user_yzx9;
in
mkHomeConfiguration {
  vars = {
    hostname = "cvcd-gpu0";
    type = "home-manager";
    system = "x86_64-linux";
    user = user_yzx9 // {
      name = "yzx";
    };
  };

  purpose = {
    daily = true;
  };
}
