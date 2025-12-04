inputs:

let
  inherit (import ../_shared.nix) user_yzx9 mkNetworkingLab;
in
inputs.self.lib.mkNixosRpiConfiguration {
  config = {
    vars = {
      hostname = "yzx9-rpi5";
      type = "nixos";
      system = "aarch64-linux";
      user = user_yzx9;
    };

    proxy.selfHost = {
      enable = true;
      public = true;
    };
  };

  host = {
    imports = [
      ./atuin.nix
      ./backup.nix
      ./freshrss.nix
      ./frpc.nix
      ./hardware-configuration.nix
      ./mysql.nix
      ./radicale.nix
      # ./trilium.nix # wait for 25.11 or customized nixpkgs
    ];

    networking = mkNetworkingLab "end0" "10.6.18.188";
  };
}
