{
  self,
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (config) vars purpose;
  inherit (pkgs.stdenvNoCC.hostPlatform) isLinux isDarwin;
in
lib.mkIf purpose.gui {
  # Allow unfree packages
  # nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ ];

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages =
    lib.optional isLinux pkgs.firefox # browser, installed using homebrew in darwin
    ++ lib.optional isDarwin pkgs.stats # macOS system monitor in your menu bar
    # daily only
    ++ lib.optionals purpose.daily (
      [
        pkgs.dbeaver-bin # SQL client
        pkgs.logseq
      ]
      ++ lib.optional isLinux pkgs.inkscape # SVG design, installed by homebrew in darwin
      ++ lib.optional isDarwin self.packages.${vars.system}.vaa3d-x # only support darwin now
    );
}
