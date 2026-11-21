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

    proxy.httpPublic = "http://10.6.141.234:12345";
  };

  home.imports = [
    ./nex.nix
  ];
}
