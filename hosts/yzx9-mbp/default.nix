inputs:

let
  inherit (import ../_shared/lib.nix inputs) mkDarwinConfiguration;
  inherit (import ../_shared/user.nix) user_yzx9;
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

  proxy.selfHost = {
    enable = true;
    public = true;
  };
  docker.enable = true;
}
