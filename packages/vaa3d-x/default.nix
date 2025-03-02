{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  unzip,
}:

let
  version = "1.1.4";
in
stdenvNoCC.mkDerivation {
  pname = "vaa3d-x";
  inherit version;

  src =
    let
      inherit (stdenvNoCC.hostPlatform) system;
      selectSystem = attrs: attrs.${system} or (throw "Unsupported system: ${system}");
      suffix = selectSystem {
        x86_64-darwin = "Mac.zip";
        aarch64-darwin = "Mac.zip";
      };
      hash = selectSystem {
        x86_64-darwin = "sha256-dj30AO+3PZ2Txwd7t8m5gQkWz/TY5hpjyfmgHnKR020=";
        aarch64-darwin = "sha256-dj30AO+3PZ2Txwd7t8m5gQkWz/TY5hpjyfmgHnKR020=";
      };
    in
    fetchurl {
      url = "https://github.com/Vaa3D/release/releases/download/v${version}/Vaa3D-x.${version}_${suffix}";
      inherit hash;
    };

  sourceRoot = "vaa3dx231101/Vaa3D-x.app";

  nativeBuildInputs = [
    makeWrapper
    unzip
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{Applications/Vaa3D-x.app,bin}
    cp -R . $out/Applications/Vaa3D-x.app
    makeWrapper $out/{Applications/Vaa3D-x.app/Contents/MacOS,bin}/Vaa3D-x \

    runHook postInstall
  '';

  preFixup = ''
    rm $out/Applications/Vaa3D-x.app/Contents/MacOS/libtiff.dylib
  '';

  meta = {
    homepage = "www.vaa3d.org";
    description = "Open source 3D/4D/5D image visualization and analysis software for bioimage analysis.";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
    maintainers = with lib.maintainers; [ yzx9 ];
    mainProgram = "Vaa3D-x";
  };
}
