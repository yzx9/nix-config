inputs:

let
  inherit (import ../_shared.nix) user_yzx;
in
inputs.self.lib.mkHomeConfiguration {
  config = {
    vars = {
      hostname = "cvcd-gpu1";
      type = "home-manager";
      system = "x86_64-linux";
      user = user_yzx;
    };

    purpose.dev.enable = true;
  };
}
