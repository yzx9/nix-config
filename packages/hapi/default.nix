{
  lib,
  stdenv,
  fetchFromGitHub,
  bun,
  nodejs,
  makeBinaryWrapper,
  ripgrep,
  difftastic,
  writableTmpDirAsHomeHook,
}:

let
  version = "0.16.7";

  inherit (stdenv.hostPlatform) system;
  selectSystem = attrs: attrs.${system} or (throw "Unsupported system: ${system}");

  target = selectSystem {
    x86_64-linux = "bun-linux-x64-baseline";
    aarch64-linux = "bun-linux-arm64";
    x86_64-darwin = "bun-darwin-x64";
    aarch64-darwin = "bun-darwin-arm64";
  };

  featureFlag = selectSystem {
    x86_64-linux = "HAPI_TARGET_LINUX_X64";
    aarch64-linux = "HAPI_TARGET_LINUX_ARM64";
    x86_64-darwin = "HAPI_TARGET_DARWIN_X64";
    aarch64-darwin = "HAPI_TARGET_DARWIN_ARM64";
  };

  src = fetchFromGitHub {
    owner = "tiann";
    repo = "hapi";
    tag = "v${version}";
    hash = "sha256-MzaC6ZCqfSgx+a+zEQWRa+Zb/7QZePucmpKgsi9BxIU=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "hapi";
  inherit version;

  # Fixed-output derivation: source + node_modules (network access allowed in sandbox)
  deps = stdenv.mkDerivation {
    inherit src version;
    pname = "${finalAttrs.pname}-deps";

    nativeBuildInputs = [
      bun
      writableTmpDirAsHomeHook
    ];

    dontConfigure = true;
    dontFixup = true;

    buildPhase = ''
      runHook preBuild

      export BUN_INSTALL_CACHE_DIR=$(mktemp -d)
      bun install --no-progress --no-cache --ignore-scripts

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      cp -R . $out

      runHook postInstall
    '';

    outputHash =
      {
        x86_64-linux = "sha256-oP3Dcu8G6Yg85bHEZZQVGCp8carV1bW/2iMoyXbrMBM=";
        aarch64-linux = "sha256-FnlrKq+Ou89lktq3Ja5ai8lzFdxdz2s6BTklQTx0QfQ=";
        aarch64-darwin = "sha256-S/u7IwWhlHqVdy50x5MZwU5EE1Wg5MNVLfNuhQHBXAQ=";
      }
      .${system} or (throw "hapi deps hash not available for ${system}");
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };

  # Use deps (source with node_modules pre-installed) as the source tree
  src = finalAttrs.deps;

  nativeBuildInputs = [
    bun
    nodejs
    makeBinaryWrapper
  ];

  # bun build --compile produces binaries that get corrupted by strip
  dontStrip = true;

  postPatch = ''
    # Replace embeddedAssets.bun.ts with empty stub — we provide rg/difft via wrapper
    cat > cli/src/runtime/embeddedAssets.bun.ts <<'STUB'
    export interface EmbeddedAsset {
        relativePath: string;
        sourcePath: string;
    }
    export async function loadEmbeddedAssets(): Promise<EmbeddedAsset[]> {
        return [];
    }
    STUB

    # Patch ensureRuntimeAssets to skip when no embedded assets (nix-managed tools)
    substituteInPlace cli/src/runtime/assets.ts \
      --replace-fail \
        'unpackTools(runtimeRoot);' \
        'if (embeddedAssets.length > 0) { unpackTools(runtimeRoot); }' \
      --replace-fail \
        'ensureTunwgExecutable(runtimeRoot);' \
        'if (embeddedAssets.length > 0) { ensureTunwgExecutable(runtimeRoot); }' \
      --replace-fail \
        "writeFileSync(markerPath, packageJson.version, 'utf-8');" \
        "if (embeddedAssets.length > 0) { writeFileSync(markerPath, packageJson.version, 'utf-8'); }"
  '';

  buildPhase = ''
    runHook preBuild

    patchShebangs node_modules

    # Build web UI assets
    bun run build:web

    # Generate embedded web assets manifest
    cd hub && bun run generate:embedded-web-assets && cd ..

    # Build CLI executable
    cd cli
    mkdir -p dist-exe/${target}
    bun build --compile \
      --no-compile-autoload-dotenv \
      --compile-executable-path=${lib.getExe bun} \
      --feature=${featureFlag} \
      --target=${target} \
      --outfile=dist-exe/${target}/hapi \
      src/bootstrap.ts

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -Dm755 dist-exe/${target}/hapi $out/bin/.hapi-wrapped
    makeWrapper $out/bin/.hapi-wrapped $out/bin/hapi \
      --prefix PATH : ${
        lib.makeBinPath [
          ripgrep
          difftastic
        ]
      }

    runHook postInstall
  '';

  meta = {
    description = "AI coding assistant CLI tool";
    homepage = "https://github.com/tiann/hapi";
    license = lib.licenses.mpl20;
    platforms = with lib.platforms; linux ++ darwin;
    maintainers = with lib.maintainers; [ yzx9 ];
    mainProgram = "hapi";
  };
})