{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs,
  nix-update-script,
}:

let
  pname = "git-conventional-commits";
  version = "2.6.7";
in
buildNpmPackage {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "qoomon";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-A5J5h6TrjPmMDQCTAn6TKTA71uu5Qe/Si32cx57vdmM=";
  };

  npmDepsHash = "sha256-8kf0Wx2YTjZDswFaLJzbxf4Tpjd3h47msOvU+JSBpWE=";

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,share/${pname}}
    cp -r ./* $out/share/${pname}

    makeWrapper "${lib.getExe nodejs}" "$out/bin/${pname}" \
      --add-flags "$out/share/${pname}/cli.js"
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    homepage = "https://github.com/qoomon/git-conventional-commits";
    description = "Git Conventional Commits Util to generate Semantic Version and Markdown Change Log and Validate Commit Message";
    license = licenses.gpl3;
    maintainers = with maintainers; [ yzx9 ];
    mainProgram = pname;
  };
}
