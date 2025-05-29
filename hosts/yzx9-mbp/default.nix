inputs:

let
  inherit (import ../../modules/_shared/lib.nix inputs) mkDarwinConfiguration;
  inherit (import ../_shared.nix) user_yzx9;
in
mkDarwinConfiguration {
  config = {
    vars = {
      hostname = "yzx9-mbp";
      type = "nix-darwin";
      system = "aarch64-darwin";
      user = user_yzx9;
    };

    purpose = {
      daily = true;
      gui = true;
      dev.enable = true;
    };

    proxy.selfHost = {
      enable = true;
      public = true;
    };
    docker.enable = true;
  };

  host.imports = [
    ./distributed-builds.nix
  ];

  home.imports = [
    ./ssh.nix
  ];
}
