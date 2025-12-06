{
  lib,
  stdenv,
  fetchFromGitHub,
  unzip,
  swift,
  versionCheckHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "macism";
  version = "3.0.10";

  src = fetchFromGitHub {
    owner = "laishulu";
    repo = "macism";
    rev = "v${finalAttrs.version}";
    hash = "sha256-TNZoVCGbWYZHWL1hgdq9p+RrbsWLtL8FuNpf0OvN+uM=";
  };

  patches = [
    ./version-check-no-init.patch
  ];

  dontConfigure = true;

  nativeBuildInputs = [
    unzip
    swift
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp macism $out/bin

    mkdir -p $out/Applications
    cp -r TemporaryWindow.app $out/Applications

    runHook postInstall
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";
  doInstallCheck = true;

  meta = {
    description = "Reliable CLI MacOS Input Source Manager";
    homepage = "https://github.com/laishulu/macism";
    maintainers = with lib.maintainers; [
      yzx9
    ];
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
    mainProgram = "macism";
  };
})
