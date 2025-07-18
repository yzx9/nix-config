{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  catppuccin-bat,
  flavor ? "mocha",
  color ? "blue",
}:

stdenvNoCC.mkDerivation {
  pname = "catppuccin-yazi";
  version = "0-unstable-2025-06-30";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "yazi";
    rev = "1a8c939e47131f2c4bd07a2daea7773c29e2a774";
    hash = "sha256-hjqmNxIr/KCN9k5ZT7O994BeWdp56NP7aS34+nZ/fQQ=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase =
    let
      capitalize =
        str:
        let
          first = lib.substring 0 1 str;
          rest = lib.substring 1 (lib.stringLength str - 1) str;
        in
        lib.toUpper first + rest;
    in
    ''
      runHook preInstall

      mkdir -p $out
      cp themes/${flavor}/catppuccin-${flavor}-${color}.toml $out/flavor.toml
      cp "${catppuccin-bat}/themes/Catppuccin ${capitalize flavor}.tmTheme" $out/tmtheme.toml

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
