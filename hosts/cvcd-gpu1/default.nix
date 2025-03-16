inputs:

let
  inherit (import ../_shared/lib.nix inputs) mkHomeConfiguration;
  inherit (import ../_shared/user.nix) user_yzx;
in
mkHomeConfiguration {
  config = {
    vars = {
      hostname = "cvcd-gpu1";
      type = "home-manager";
      system = "x86_64-linux";
      user = user_yzx;
    };

    purpose = {
      daily = true;
    };
  };
}
