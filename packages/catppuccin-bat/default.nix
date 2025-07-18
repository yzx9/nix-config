{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation {
  pname = "catppuccin-bat";
  version = "0-unstable-2025-06-30";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "bat";
    rev = "6810349b28055dce54076712fc05fc68da4b8ec0";
    hash = "sha256-lJapSgRVENTrbmpVyn+UQabC9fpV1G1e+CdlJ090uvg=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/themes
    cp -r themes/ $out

    runHook postInstall
  '';

  meta = {
    description = "Soothing pastel theme for bat";
    homepage = "https://github.com/catppuccin/bat";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ yzx9 ];
    platforms = lib.platforms.all;
  };
}
