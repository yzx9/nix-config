{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

let
  inherit (config) vars purpose;
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin;
in
lib.mkIf purpose.gui {
  # Allow unfree packages
  # nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ ];

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages =
    lib.optionals isDarwin [
      pkgs.stats # system monitor in your menu bar
      pkgs.maccy # clipboard manager
    ]
    # daily only
    ++ lib.optionals purpose.daily (
      [
        pkgs.element-desktop
        pkgs.logseq # knowledge base
        pkgs.dbeaver-bin # SQL client
        pkgs.inkscape # SVG design
        pkgs.zotero # reference manager, with two plugins: zotero-better-bibtex, zotmoov ({%w}/{%y})
      ]
      ++ lib.optionals isDarwin [
        inputs.self.packages.${vars.system}.vaa3d-x # only support darwin now
      ]
    );
}
