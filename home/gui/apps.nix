{
  self,
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (config) vars purpose;
  inherit (pkgs.stdenvNoCC.hostPlatform) isLinux isDarwin isAarch64;
in
{
  config = lib.mkIf purpose.gui {
    # Allow unfree packages
    # nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ ];

    # The home.packages option allows you to install Nix packages into your
    # environment.
    home.packages = lib.optionals purpose.daily (
      [
        pkgs.dbeaver-bin # SQL client
      ]
      ++ lib.optionals (!(isLinux && isAarch64)) [
        pkgs.logseq # broken in aarch64-linux
      ]
      # linux only
      ++ lib.optionals isLinux [
        pkgs.inkscape # SVG design, install using homebrew in darwin
      ]
      # darwin only
      ++ lib.optionals isDarwin [
        self.packages.${vars.system}.vaa3d-x
        pkgs.stats
      ]
    );
  };
}
