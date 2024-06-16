{ lib
, stdenvNoCC
, fetchurl
, makeWrapper
, undmg
, openjdk17
, gnused
, wrapGAppsHook3
, autoPatchelfHook
}:

let
  pname = "dbeaver-bin";
  version = "24.0.5";
  meta = with lib; {
    homepage = "https://dbeaver.io/";
    description = "Universal SQL Client for developers, DBA and analysts. Supports MySQL, PostgreSQL, MariaDB, SQLite, and more";
    longDescription = ''
      Free multi-platform database tool for developers, SQL programmers, database
      administrators and analysts. Supports all popular databases: MySQL,
      PostgreSQL, MariaDB, SQLite, Oracle, DB2, SQL Server, Sybase, MS Access,
      Teradata, Firebird, Derby, etc.
    '';
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.asl20;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    maintainers = with maintainers; [ gepbird mkg20001 ];
    mainProgram = "dbeaver";
  };

  src =
    let
      inherit (stdenvNoCC.hostPlatform) system;
      selectSystem = attrs: attrs.${system} or (throw "Unsupported system: ${system}");
      suffix = selectSystem {
        x86_64-linux = "linux.gtk.x86_64-nojdk.tar.gz";
        aarch64-linux = "linux.gtk.aarch64-nojdk.tar.gz";
        x86_64-darwin = "macos-x86_64.dmg";
        aarch64-darwin = "macos-aarch64.dmg";
      };
      hash = selectSystem {
        x86_64-linux = "sha256-q6VIr55hXn47kZrE2i6McEOfp2FBOvwB0CcUnRHFMZs=";
        aarch64-linux = "sha256-Xn3X1C31UALBAsZIGyMWdp0HNhJEm5N+7Go7nMs8W64=";
        x86_64-darwin = "sha256-XOQaMNQHOC4dVJXIUn4l4Oa7Gohbq+JMDFusIy/U+tc=";
        aarch64-darwin = "sha256-554ea5p1MR4XIHtSeByd4S/Ke4cKRZbITTNRRDoRqPI=";
      };
    in
    fetchurl {
      url = "https://github.com/dbeaver/dbeaver/releases/download/${version}/dbeaver-ce-${version}-${suffix}";
      inherit hash;
    };

  linux = stdenvNoCC.mkDerivation
    (finalAttrs: {
      inherit pname version src meta;

      nativeBuildInputs = [
        makeWrapper
        gnused
        wrapGAppsHook3
        autoPatchelfHook
      ];

      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall
        mkdir -p $out/opt/dbeaver $out/bin
        cp -r * $out/opt/dbeaver
        makeWrapper $out/opt/dbeaver/dbeaver $out/bin/dbeaver \
          --prefix PATH : "${openjdk17}/bin" \
          --set JAVA_HOME "${openjdk17.home}"

        mkdir -p $out/share/icons/hicolor/256x256/apps
        ln -s $out/opt/dbeaver/dbeaver.png $out/share/icons/hicolor/256x256/apps/dbeaver.png

        mkdir -p $out/share/applications
        ln -s $out/opt/dbeaver/dbeaver-ce.desktop $out/share/applications/dbeaver.desktop

        substituteInPlace $out/opt/dbeaver/dbeaver-ce.desktop \
          --replace-fail "/usr/share/dbeaver-ce/dbeaver.png" "dbeaver" \
          --replace-fail "/usr/share/dbeaver-ce/dbeaver" "$out/bin/dbeaver"

        sed -i '/^Path=/d' $out/share/applications/dbeaver.desktop

        runHook postInstall
      '';

      passthru.updateScript = ./update.sh;
    });

  darwin = stdenvNoCC.mkDerivation (finalAttrs: {
    inherit pname version src meta;

    nativeBuildInputs = [
      makeWrapper
      undmg
    ];

    dontConfigure = true;
    dontBuild = true;

    sourceRoot = "dbeaver.app";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/{Applications/dbeaver.app,bin}
      cp -R . $out/Applications/dbeaver.app
      makeWrapper $out/{Applications/dbeaver.app/Contents/MacOS,bin}/dbeaver \
        --prefix PATH : "${openjdk17}/bin" \
        --set JAVA_HOME "${openjdk17.home}"

      runHook postInstall
    '';

    passthru.updateScript = ./update.sh;
  });
in
if stdenvNoCC.isDarwin then darwin else linux
