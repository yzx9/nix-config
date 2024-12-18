inputs:

let
  inherit (import ../_shared.nix inputs) mkDarwinConfiguration;
  dict = import ../_dict.nix;
in
mkDarwinConfiguration {
  vars = {
    hostname = "yzx9-mbp";
    type = "nix-darwin";
    system = "aarch64-darwin";
    user = dict.user_yzx9;
  };

  purpose = {
    daily = true;
    gui = true;
  };

  proxy.enable = true;
  docker.enable = true;
}
