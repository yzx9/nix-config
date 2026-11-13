{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin;
in
lib.mkIf config.my.host.gui {
  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages =
    with pkgs;
    lib.optionals isDarwin [
      stats # system monitor in your menu bar
      maccy # clipboard manager
      # scroll-reverser # reverse the direction of scrolling
    ]
    ++ lib.optionals config.my.host.daily (
      [
        super-productivity # task management
        dbeaver-bin # SQL client
        trilium-desktop # note taking app
        zotero # reference manager, with two plugins: zotero-better-bibtex, zotmoov ({%w}/{%y})

        meshlab # 3D mesh processing

        # design
        # openscad # 3D parametric design
        # blender # 3D design
      ]
      ++ lib.optionals isDarwin (
        let
          mkAppWithProxy =
            name: appName:
            pkgs.writeShellApplication {
              inherit name;
              text = ''
                open -a ${appName} \
                  --env HTTP_PROXY="${config.my.proxy.http}" \
                  --env HTTPS_PROXY="${config.my.proxy.http}" \
                  --env NO_PROXY="localhost,127.0.0.1,::1" \
                  --args \
                  --proxy-server="${config.my.proxy.socks5}" \
                  "$@"
              '';
            };
        in
        [
          yzx9.vaa3d-x # only support darwin now

          # installed via brew, add a wrapper to set the proxy for it
          (mkAppWithProxy "element-desktop" "Element")
          (mkAppWithProxy "chatgpt" "ChatGPT")
        ]
      )
      ++ lib.optionals (!isDarwin) [
        element-desktop # Matrix client

        # design
        inkscape # SVG design, broken on darwin: #383860
      ]
    );
}
