inputs:

let
  inherit (import ../../modules/_shared/lib.nix inputs) mkHomeConfiguration;
  inherit (import ../_shared.nix) user_yzx;
in
mkHomeConfiguration {
  config = {
    vars = {
      hostname = "cvcd-gpu0";
      type = "home-manager";
      system = "x86_64-linux";
      user = user_yzx;
    };

    purpose = {
      daily = true;
    };
  };
}
