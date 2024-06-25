{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  unzip,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "vaa3d-x";
  version = "1.1.4";

  src =
    let
      inherit (stdenvNoCC.hostPlatform) system;
      selectSystem = attrs: attrs.${system} or (throw "Unsupported system: ${system}");
      suffix = selectSystem { aarch64-darwin = "Mac.zip"; };
      hash = selectSystem { aarch64-darwin = "sha256-dj30AO+3PZ2Txwd7t8m5gQkWz/TY5hpjyfmgHnKR020="; };
    in
    fetchurl {
      url = "https://github.com/Vaa3D/release/releases/download/v${finalAttrs.version}/Vaa3D-x.${finalAttrs.version}_${suffix}";
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

  meta = with lib; {
    homepage = "www.vaa3d.org";
    description = "Open source 3D/4D/5D image visualization and analysis software for bioimage analysis.";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.mit;
    platforms = [ "aarch64-darwin" ];
    maintainers = with maintainers; [ yzx9 ];
    mainProgram = "Vaa3D-x";
  };
})
