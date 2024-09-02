{
  lib,
  stdenv,
  fetchurl,
  appimageTools,
  undmg,
  makeWrapper,
  # Notice: graphs will not sync without matching upstream's major electron version
  #         the specific electron version is set at top-level file to preserve override interface.
  #         whenever updating this package also sync electron version at top-level file.
  electron,
  autoPatchelfHook,
  git,
  nix-update-script,
}:

stdenv.mkDerivation (
  finalAttrs:
  let
    inherit (finalAttrs) pname version src;

    inherit (stdenv.hostPlatform) system;
    selectSystem = attrs: attrs.${system} or (throw "Unsupported system: ${system}");
    suffix = selectSystem {
      x86_64-linux = "linux-x64-${version}.AppImage";
      aarch64-linux = "linux-arm64-${version}.AppImage";
      x86_64-darwin = "drawin-x64-${version}.dmg";
      aarch64-darwin = "darwin-arm64-${version}.dmg";
    };
    hash = selectSystem {
      x86_64-linux = "sha256-cJcjUoZSpD87jy4GGIxMinZW4gxRZfcGO0GdGUGXI6g=";
      aarch64-linux = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      x86_64-darwin = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      aarch64-darwin = "sha256-ZOwLa4GKsqRJv9Cq5ElFeKwtJRoFdeXOJOeJmUUd9M0=";
    };
  in
  {
    pname = "logseq";
    version = "0.10.9";

    src = fetchurl {
      inherit hash;
      url = "https://github.com/logseq/logseq/releases/download/${version}/logseq-${suffix}";
      name = if (!stdenv.isDarwin) then "${pname}-${version}.AppImage" else "${pname}-${version}.dmg";
    };

    nativeBuildInputs =
      [ makeWrapper ]
      ++ lib.optionals (!stdenv.isDarwin) [ autoPatchelfHook ] ++ lib.optionals stdenv.isDarwin [ undmg ];
    buildInputs = [ stdenv.cc.cc.lib ];

    dontUnpack = !stdenv.isDarwin;
    sourceRoot = "Logseq.app";

    dontConfigure = true;
    dontBuild = true;

    installPhase =
      if (!stdenv.isDarwin) then
        (
          let
            appimageContents = appimageTools.extract { inherit pname src version; };
          in
          ''
            runHook preInstall

            mkdir -p $out/bin $out/share/${pname} $out/share/applications
            cp -a ${appimageContents}/{locales,resources} $out/share/${pname}
            cp -a ${appimageContents}/Logseq.desktop $out/share/applications/${pname}.desktop

            # remove the `git` in `dugite` because we want the `git` in `nixpkgs`
            chmod +w -R $out/share/${pname}/resources/app/node_modules/dugite/git
            chmod +w $out/share/${pname}/resources/app/node_modules/dugite
            rm -rf $out/share/${pname}/resources/app/node_modules/dugite/git
            chmod -w $out/share/${pname}/resources/app/node_modules/dugite

            mkdir -p $out/share/pixmaps
            ln -s $out/share/${pname}/resources/app/icons/logseq.png $out/share/pixmaps/${pname}.png

            substituteInPlace $out/share/applications/${pname}.desktop \
              --replace Exec=Logseq Exec=${pname} \
              --replace Icon=Logseq Icon=${pname}

            runHook postInstall
          ''
        )
      else
        ''
          runHook preInstall

          mkdir -p $out/{Applications/Logseq.app,bin}
          cp -R . $out/Applications/Logseq.app 
          makeWrapper $out/Applications/Logseq.app/Contents/MacOS/Logseq $out/bin/${pname}

          runHook postInstall
        '';

    postFixup = lib.optionalString (!stdenv.isDarwin) ''
      # set the env "LOCAL_GIT_DIRECTORY" for dugite so that we can use the git in nixpkgs
      makeWrapper ${lib.getBin electron} $out/bin/${pname} \
        --set "LOCAL_GIT_DIRECTORY" ${git} \
        --add-flags $out/share/${pname}/resources/app \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"
    '';

    passthru.updateScript = nix-update-script { };

    meta = {
      description = "Local-first, non-linear, outliner notebook for organizing and sharing your personal knowledge base";
      homepage = "https://github.com/logseq/logseq";
      changelog = "https://github.com/logseq/logseq/releases/tag/${version}";
      license = lib.licenses.agpl3Plus;
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
      maintainers = with lib.maintainers; [ ];
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      mainProgram = "logseq";
    };
  }
)