{
  lib,
  stdenv,
  fetchFromGitHub,
  makeBinaryWrapper,
  writableTmpDirAsHomeHook,
  nodejs,
  bun,
  perl,
  playwright-driver,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gstack";
  version = "0-unstable-2026-04-17";
  src = fetchFromGitHub {
    owner = "garrytan";
    repo = "gstack";
    rev = "1211b6b40becb684eaf29b0f30a650a8a9b222a5";
    hash = "sha256-0mVE49Bd7ORlZ4gEY5ovxY60ttWK72rGFPRLLdrd+O0=";
  };

  # Fixed-output derivation for node_modules (network access allowed in sandbox)
  node_modules = stdenv.mkDerivation {
    inherit (finalAttrs) src version;
    pname = "${finalAttrs.pname}-node_modules";

    nativeBuildInputs = [
      bun
      writableTmpDirAsHomeHook
    ];

    dontConfigure = true;
    dontFixup = true;

    buildPhase = ''
      runHook preBuild

      export BUN_INSTALL_CACHE_DIR=$(mktemp -d)
      bun install --no-progress --frozen-lockfile --no-cache --ignore-scripts

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -R ./node_modules $out/node_modules

      runHook postInstall
    '';

    outputHash =
      {
        x86_64-linux = "sha256-S3Ls/ZjhcVILfgpzNjLA4JOfaFYCbBPbDJla1jh5Jf4=";
        aarch64-linux = "sha256-ybWkYsWw66Ob4OG3hPV+BadNm0JfLi7WoUBckzeB+zc=";
        aarch64-darwin = "sha256-U4tG7eFBPILKtyPELWc7j0sgUXBq8U5AMNADBzcRi+M=";
      }
      .${stdenv.hostPlatform.system}
        or (throw "gstack node_modules hash not available for ${stdenv.hostPlatform.system}");
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };

  nativeBuildInputs = [
    bun
    nodejs
    perl
    makeBinaryWrapper
  ];

  # bun build --compile produces binaries that get corrupted by strip
  dontStrip = true;

  buildPhase = ''
    runHook preBuild

    # Install pre-fetched node_modules
    cp -R ${finalAttrs.node_modules}/node_modules .
    patchShebangs node_modules

    # Generate skill docs from .tmpl templates
    bun run gen:skill-docs --host all

    # Build standalone binaries (bun build --compile = self-contained)
    mkdir -p browse/dist design/dist

    bun build --compile browse/src/cli.ts --outfile browse/dist/browse
    bun build --compile browse/src/find-browse.ts --outfile browse/dist/find-browse
    bun build --compile design/src/cli.ts --outfile design/dist/design
    bun build --compile bin/gstack-global-discover.ts --outfile bin/gstack-global-discover

    # Node.js server bundle (uses perl for post-processing)
    bash browse/scripts/build-node-server.sh

    # Version files (replace git rev-parse which won't work in sandbox)
    echo "${finalAttrs.src.rev}" > browse/dist/.version
    echo "${finalAttrs.src.rev}" > design/dist/.version

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    dest=$out/share/gstack
    mkdir -p $dest

    # ── Root files ──
    cp SKILL.md $dest/
    cp ETHOS.md $dest/
    cp VERSION $dest/

    # ── Compiled binaries ──
    mkdir -p $dest/browse/dist $dest/browse/bin $dest/design/dist $dest/bin

    # browse binary needs bun in PATH (spawns bun to run server.ts)
    # and PLAYWRIGHT_BROWSERS_PATH to find nix-managed browsers
    install -m755 browse/dist/browse $dest/browse/dist/.browse-wrapped
    makeWrapper $dest/browse/dist/.browse-wrapped $dest/browse/dist/browse \
      --prefix PATH : ${lib.makeBinPath [ bun ]} \
      --set PLAYWRIGHT_BROWSERS_PATH ${playwright-driver.browsers}

    install -m755 browse/dist/find-browse $dest/browse/dist/
    install -m755 browse/dist/server-node.mjs $dest/browse/dist/
    install -m644 browse/dist/.version $dest/browse/dist/

    # Copy polyfill if it exists (may not be generated on all platforms)
    [ -f browse/dist/bun-polyfill.cjs ] && install -m644 browse/dist/bun-polyfill.cjs $dest/browse/dist/

    # Source files needed by browse binary at runtime (resolves server.ts relative to binary)
    cp -r browse/src $dest/browse/src

    install -m755 design/dist/design $dest/design/dist/
    install -m644 design/dist/.version $dest/design/dist/

    # Source files needed by design binary at runtime
    cp -r design/src $dest/design/src

    install -m755 bin/gstack-global-discover $dest/bin/

    # ── Shell scripts from bin/ ──
    for script in bin/gstack-* bin/chrome-cdp; do
      if [ -f "$script" ]; then
        install -m755 "$script" $dest/$script
      fi
    done

    # ── Browse bin scripts ──
    for script in browse/bin/*; do
      if [ -f "$script" ]; then
        install -m755 "$script" $dest/$script
      fi
    done

    # ── Skill directories (each with SKILL.md) ──
    for dir in */; do
      dir=''${dir%/}
      # Skip non-skill directories
      case "$dir" in
        node_modules|.git|dist|benchmark|test|docs|extension|supabase|lib|scripts|learn) continue ;;
      esac
      if [ -f "$dir/SKILL.md" ]; then
        mkdir -p $dest/$dir
        cp "$dir/SKILL.md" $dest/$dir/
        # Copy supporting files (data, checklists, etc.)
        for item in "$dir"/*; do
          name=$(basename "$item")
          case "$name" in
            SKILL.md|SKILL.md.tmpl|src|test|dist|bin|scripts|node_modules|*.ts|*.js) continue ;;
          esac
          if [ -f "$item" ]; then
            cp "$item" $dest/$dir/
          elif [ -d "$item" ]; then
            cp -r "$item" $dest/$dir/
          fi
        done
      fi
    done

    # ── Library files ──
    if [ -d lib ]; then
      cp -r lib $dest/
    fi

    # ── Wrapper for browse CLI ──
    mkdir -p $out/bin
    makeWrapper $dest/browse/dist/browse $out/bin/browse \
      --prefix PATH : ${lib.makeBinPath [ bun ]} \
      --set PLAYWRIGHT_BROWSERS_PATH ${playwright-driver.browsers}

    runHook postInstall
  '';

  meta = {
    description = "Claude Code skills + fast headless browser";
    homepage = "https://github.com/garrytan/gstack";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin ++ lib.platforms.linux;
    mainProgram = "browse";
  };
})
