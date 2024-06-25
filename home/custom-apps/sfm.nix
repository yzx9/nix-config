{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  makeWrapper,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "sfm";
  version = "1.9.2";

  src =
    let
      inherit (stdenvNoCC.hostPlatform) system;
      selectSystem = attrs: attrs.${system} or (throw "Unsupported system: ${system}");
      hash = selectSystem { aarch64-darwin = "sha256-dIEReLZVxisrQkZouk7DUXhOeNwJo5j+8uVQWj/9v9Q="; };
    in
    fetchurl {
      url = "https://github.com/SagerNet/sing-box/releases/download/v${finalAttrs.version}/SFM-${finalAttrs.version}-universal.zip";
      inherit hash;
    };

  nativeBuildInputs = [
    makeWrapper
    unzip
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{Applications/${finalAttrs.pname}.app,bin}
    cp -R . $out/Applications/${finalAttrs.pname}.app
    makeWrapper $out/{Applications/${finalAttrs.pname}.app/Contents/MacOS,bin}/${finalAttrs.pname} \

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://github.com/SagerNet/sing-box";
    description = "The universal proxy platform";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.asl20;
    platforms = platforms.linux ++ platforms.darwin;
    maintainers = with maintainers; [ yzx9 ];
    mainProgram = "${finalAttrs.pname}";
  };
})
