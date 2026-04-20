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

        meshlab # 3D mesh processing

        # design
        # openscad # 3D parametric design
      ]
      ++ lib.optionals isDarwin [
        yzx9.vaa3d-x # only support darwin now

        (pkgs.writeShellApplication {
          name = "element-desktop";
          text = ''
            open -a Element --args --proxy-server=socks5://${config.proxy.socksProxy}
          '';
        }) # element was installed via brew, so we add a wrapper to set the proxy for it
      ]
      ++ lib.optionals (!isDarwin) [
        element-desktop # Matrix client

        # design
        blender # 3D design, broken on darwin: #429309
        inkscape # SVG design, broken on darwin: #383860
      ]
    );
}
