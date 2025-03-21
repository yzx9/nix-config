{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nix-update-script,
}:

let
  version = "2.6.7";
in
buildNpmPackage {
  pname = "git-conventional-commits";
  inherit version;

  src = fetchFromGitHub {
    owner = "qoomon";
    repo = "git-conventional-commits";
    tag = "v${version}";
    hash = "sha256-A5J5h6TrjPmMDQCTAn6TKTA71uu5Qe/Si32cx57vdmM=";
  };

  npmDepsHash = "sha256-8kf0Wx2YTjZDswFaLJzbxf4Tpjd3h47msOvU+JSBpWE=";

  dontNpmBuild = true;

  passthru.updateScript = nix-update-script { };

  meta = {
    homepage = "https://github.com/qoomon/git-conventional-commits";
    description = "Generate semantic version, markdown changelogs, and validate commit messages";
    changelog = "https://github.com/qoomon/git-conventional-commits/blob/master/CHANGELOG.md";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [ yzx9 ];
    mainProgram = "git-conventional-commits";
  };
}
