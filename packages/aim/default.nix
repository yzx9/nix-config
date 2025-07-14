{
  lib,
  rustPlatform,
  fetchFromGitHub,
  testers,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "aim";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "yzx9";
    repo = "aim";
    tag = "v${finalAttrs.version}";
    hash = "sha256-dIePBA8K65UNXcfFG2Y8kb+zd5gxtiHlF0TcNWhtSR4=";
  };

  cargoHash = "sha256-jP/CaH6lAsFXqTHGQI/dgwLCVjXJ8yQAH0FzRNhjA94=";

  passthru.tests = {
    version = testers.version {
      package = finalAttrs.finalPackage;
      version = finalAttrs.version;
    };
  };

  meta = {
    description = "An Information Manager";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
    mainProgram = "aim";
  };
})
