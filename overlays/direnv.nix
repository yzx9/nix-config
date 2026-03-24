{ ... }:

final: prev:

{
  direnv = prev.direnv.overrideAttrs (
    prevAttrs: {
      # Backport NixOS/nixpkgs#502769: external linkmode breaks with CGO disabled.
      postPatch = (prevAttrs.postPatch or "") + ''
        substituteInPlace GNUmakefile --replace-fail " -linkmode=external" ""
      '';
    }
  );
}
