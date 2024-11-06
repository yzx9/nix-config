{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.gui;

  vaa3d-x = pkgs.callPackage ./pkgs/vaa3d-x.nix { };
in
{
  config = lib.mkIf cfg.enable {
    # Allow unfree packages
    # nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ ];

    # The home.packages option allows you to install Nix packages into your
    # environment.
    home.packages =
      (with pkgs; [
        gopass-jsonapi # you have to run `gopass-jsonapi configure` manually, because I dont know how to do it automatically
        dbeaver-bin # SQL client
        yarr
        logseq
      ])
      # customized apps
      ++ [ ]
      # darwin will install these apps using homebrew
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux (
        with pkgs;
        [
          inkscape # SVG design
        ]
      )
      # darwin only
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        pkgs.stats
        vaa3d-x
      ];
  };
}
