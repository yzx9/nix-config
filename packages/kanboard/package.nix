{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation (attrs: {
  pname = "kanboard";
  version = "1.2.42";

  src = fetchFromGitHub {
    owner = "kanboard";
    repo = "kanboard";
    rev = "v${attrs.version}";
    hash = "sha256-/Unxl9Vh9pEWjO89sSviGGPFzUwxdb1mbOfpTFTyRL0=";
  };

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/share/kanboard
    cp -rv . $out/share/kanboard
  '';

  meta = with lib; {
    description = "Kanban project management software";
    homepage = "https://kanboard.org";
    license = licenses.mit;
    maintainers = with maintainers; [ yzx9 ];
  };
})
