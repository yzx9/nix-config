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
        zotero # reference manager, with two plugins: zotero-better-bibtex, zotmoov ({%w}/{%y})

        (logseq.overrideAttrs (
          finalAttrs: prevAttrs: {
            nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [
              darwin.autoSignDarwinBinariesHook
            ];
          }
        )) # knowledge base

        # design
        blender # 3D design
        openscad # 3D parametric design, broken on darwin
        inkscape # SVG design
      ]
      ++ lib.optionals isDarwin [
        vaa3d-x # only support darwin now
      ]
    );
}
