{
  self,
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (config) vars purpose;
in
{
  config = lib.mkIf purpose.gui {
    # Allow unfree packages
    # nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ ];

    # The home.packages option allows you to install Nix packages into your
    # environment.
    home.packages = [
        pkgs.dbeaver-bin # SQL client
      ]
      ++ lib.optionals (with pkgs.stdenv.hostPlatform; !(isLinux && isAarch64)) [
        pkgs.logseq
      ]
      # darwin will install these apps using homebrew
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.inkscape # SVG design
      ]
      # darwin only
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        self.packages.${vars.system}.vaa3d-x
        pkgs.stats
      ];
  };
}
