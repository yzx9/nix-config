inputs:

let
  inherit (import ../_lib.nix inputs) mkDarwinConfiguration;
  inherit (import ../_shared.nix) user_yzx9;
in
mkDarwinConfiguration {
  vars = {
    hostname = "yzx9-mbp";
    type = "nix-darwin";
    system = "aarch64-darwin";
    user = user_yzx9;
  };

  purpose = {
    daily = true;
    gui = true;
  };

  proxy.enable = true;
  docker.enable = true;
}
