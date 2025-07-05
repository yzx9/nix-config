{
  lib,
  stdenv,
  fetchurl,
  unzip,
  swift,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "macism";
  version = "1.3.3";

  src = fetchurl {
    url = "https://github.com/laishulu/macism/archive/refs/tags/v${finalAttrs.version}.zip";
    hash = "sha256-1A86UOxas+pps2erUZlnEF042jXyVK7dUeQsFs2bPx0=";
  };

  dontConfigure = true;

  nativeBuildInputs = [
    unzip
    swift
  ];

  buildPhase = ''
    swiftc macism.swift
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp macism $out/bin

    runHook postInstall
  '';

  meta = {
    description = "Command line MacOS Input Source Manager";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
    mainProgram = "macism";
  };
})
