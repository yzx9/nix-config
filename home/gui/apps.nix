{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (config) purpose;
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin;
in
lib.mkIf purpose.gui {
  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages =
    with pkgs;
    lib.optionals isDarwin [
      stats # system monitor in your menu bar
      maccy # clipboard manager
    ]
    ++ lib.optionals purpose.daily (
      [
        dbeaver-bin # SQL client
        trilium-desktop # note taking app
        zotero # reference manager, with two plugins: zotero-better-bibtex, zotmoov ({%w}/{%y})

        # design
        openscad # 3D parametric design
        inkscape # SVG design, broken on darwin: #383860
      ]
      ++ lib.optionals isDarwin [
        vaa3d-x # only support darwin now
      ]
      ++ lib.optionals (!isDarwin) [
        logseq # knowledge base, broken on darwin

        # design
        blender # 3D design, broken on darwin: #429309
      ]
    );
}
