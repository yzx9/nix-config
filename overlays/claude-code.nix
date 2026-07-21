# Pin claude-code to 2.1.216.
#
# claude-code's version and per-platform binary checksum live in a manifest
# (pkgs/by-name/cl/claude-code/manifest.json) that package.nix reads via
# lib.importJSON — a `let` binding, so it can't be reached by overrideAttrs.
# Instead we re-derive `version` + `src` from a local copy manifest and let
# the rest of the derivation (installPhase, versionCheckHook, meta) carry
# over unchanged. Checksums are the SHA-256 of the `claude` binary published
# at downloads.claude.ai/claude-code-releases/<version>/<platform>/claude.
{ ... }:

final: prev:

let
  manifest = {
    version = "2.1.216";
    platforms = {
      darwin-arm64.checksum = "d01b49210d72ecbe277a2665d104bacccddf2d22185be99446d2929e0edfc48d";
      darwin-x64.checksum = "e17cdc51437bd7a80ce0244d25045f568d67b212eea4ff81b83ee90f8666e42f";
      linux-arm64.checksum = "9e3a6aecc5164f607e1183aea2092c7d7705d146e504a6207df291776996a8ea";
      linux-x64.checksum = "74deca45220b8080ec75ab099bd5a5980e41a2b5879846a008fb115d436de085";
    };
  };
  platformKey = "${final.stdenv.hostPlatform.node.platform}-${final.stdenv.hostPlatform.node.arch}";
  entry =
    manifest.platforms.${platformKey}
      or (throw "claude-code overlay has no ${manifest.version} checksum for ${platformKey}");
in
{
  claude-code = prev.claude-code.overrideAttrs (old: {
    inherit (manifest) version;
    src = final.fetchurl {
      url = "https://downloads.claude.ai/claude-code-releases/${manifest.version}/${platformKey}/claude";
      sha256 = entry.checksum;
    };
  });
}
