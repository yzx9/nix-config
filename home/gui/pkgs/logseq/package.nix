{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchYarnDeps,
  fetchMavenArtifact,
  fetchgit,
  fixup-yarn-lock,
  clojure,
  yarn,
  # Notice: graphs will not sync without matching upstream's major electron version
  #         the specific electron version is set at top-level file to preserve override interface.
  #         whenever updating this package also sync electron version at top-level file.
  electron,
  makeWrapper,
  autoPatchelfHook,
  git,
  nix-update-script,
}:

let
  pname = "logseq";
  version = "0.10.9";

  src = fetchFromGitHub {
    owner = "logseq";
    repo = pname;
    hash = "sha256-2DrxXC/GT0ZwbX9DQwG9e6h4urkMH2OCaLCEiQuo0PA=";
    rev = "refs/tags/${version}";
  };

  defaultYarnOpts = [ "frozen-lockfile" "non-interactive" "no-progress" ];

  offlineCache = fetchYarnDeps {
    yarnLock = "${src}/yarn.lock";
    hash = "sha256-HHGkmiZCAtXiNeX+s+26E2WbcNH5rOSbPDYFmB6Q6xg=";
  };

  offlineCacheStatic = fetchYarnDeps {
    yarnLock = "${src}/static/yarn.lock";
    hash = "";
  };

  cljsdeps = import ./deps.nix { inherit fetchMavenArtifact fetchgit lib; };
  classp  = cljsdeps.makeClasspaths {};
in
stdenv.mkDerivation (finalAttrs: {
    inherit pname version src;

    nativeBuildInputs =
      [ makeWrapper fixup-yarn-lock clojure yarn ]
      ++ lib.optionals stdenv.isLinux [ autoPatchelfHook ];
    buildInputs = [ stdenv.cc.cc.lib ];

    patchPhase = ''
      runHook prePatch

      export HOME=$TMPDIR

      # set default yarn opts
      ${lib.concatMapStrings (option: ''
        yarn --offline config set ${option}
      '') defaultYarnOpts}

      # set offline mirror to yarn cache we created in previous steps
      yarn config --offline set yarn-offline-mirror ${offlineCache}
      fixup-yarn-lock yarn.lock
      yarn --offline --ignore-platform --ignore-scripts install

      cd static
      yarn config --offline set yarn-offline-mirror ${offlineCacheStatic}
      fixup-yarn-lock yarn.lock
      yarn --offline --ignore-platform --ignore-scripts install
      cd ..

      runHook postPatch
    '';

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      yarn bin gulp build
      yarn cljs:release-electron -Scp ${classp} -Scp jar/dir

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
    '' + lib.optionalString stdenv.isLinux ''
      mkdir -p $out/bin $out/share/${finalAttrs.pname} $out/share/applications
      cp -a $out/{locales,resources} $out/share/${finalAttrs.pname}
      cp -a $out/Logseq.desktop $out/share/applications/${finalAttrs.pname}.desktop

      # remove the `git` in `dugite` because we want the `git` in `nixpkgs`
      chmod +w -R $out/share/${finalAttrs.pname}/resources/app/node_modules/dugite/git
      chmod +w $out/share/${finalAttrs.pname}/resources/app/node_modules/dugite
      rm -rf $out/share/${finalAttrs.pname}/resources/app/node_modules/dugite/git
      chmod -w $out/share/${finalAttrs.pname}/resources/app/node_modules/dugite

      mkdir -p $out/share/pixmaps
      ln -s $out/share/${finalAttrs.pname}/resources/app/icons/logseq.png $out/share/pixmaps/${finalAttrs.pname}.png

      substituteInPlace $out/share/applications/${finalAttrs.pname}.desktop \
        --replace Exec=Logseq Exec=${finalAttrs.pname} \
        --replace Icon=Logseq Icon=${finalAttrs.pname}
    '' + lib.optionalString stdenv.isDarwin ''
      mkdir -p $out/{Applications/Logseq.app,bin}
      cp -R . $out/Applications/Logseq.app 
      makeWrapper $out/Applications/Logseq.app/Contents/MacOS/Logseq $out/bin/${finalAttrs.pname}
    '' + ''
      runHook postInstall
    '';

    postFixup = lib.optionalString stdenv.isLinux ''
      # set the env "LOCAL_GIT_DIRECTORY" for dugite so that we can use the git in nixpkgs
      makeWrapper ${lib.getBin electron} $out/bin/${finalAttrs.pname} \
        --set "LOCAL_GIT_DIRECTORY" ${git} \
        --add-flags $out/share/${finalAttrs.pname}/resources/app \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"
    '';

    passthru.updateScript = nix-update-script { };

    meta = {
      description = "Local-first, non-linear, outliner notebook for organizing and sharing your personal knowledge base";
      homepage = "https://github.com/logseq/logseq";
      changelog = "https://github.com/logseq/logseq/releases/tag/${finalAttrs.version}";
      license = lib.licenses.agpl3Plus;
      sourceProvenance = with lib.sourceTypes; [ fromSource ];
      maintainers = with lib.maintainers; [ ];
      platforms = electron.meta.platforms;
      mainProgram = "logseq";
    };
  }
)
