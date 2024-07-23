{ config, pkgs, lib, ... }:

let
  cfg = config.gui;

  logseq = pkgs.callPackage ../custom-apps/logseq.nix { };
  macism = pkgs.callPackage ../custom-apps/macism.nix { };
  vaa3d-x = pkgs.callPackage ../custom-apps/vaa3d-x.nix { };
in
{
  config = lib.mkIf cfg.enable {
  # Allow unfree packages
  # nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ ];

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages =
    (with pkgs;
    [
      gopass-jsonapi # you have to run `gopass-jsonapi configure` manually, because I dont know how to do it automatically
      inkscape # SVG design
      dbeaver-bin # SQL client
      yarr
    ])
    ++ [ 
      logseq
      vaa3d-x
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      macism # IME mode detect
    ];
  };
}
