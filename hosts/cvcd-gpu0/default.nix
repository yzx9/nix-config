inputs:

let
  inherit (import ../_shared.nix) user_yzx;
in
inputs.self.lib.mkHomeConfiguration {
  config.my = {
    hostname = "cvcd-gpu0";
    type = "home-manager";
    system = "x86_64-linux";
    user = user_yzx;

    host.dev.enable = true;
  };
}
