# TODO: drop once nixpkgs-unstable ships claude-code 2.1.212.
#
# claude-code's version and per-platform binary checksum live in a manifest
# (pkgs/by-name/cl/claude-code/manifest.json) that package.nix reads via
# lib.importJSON — a `let` binding, so it can't be reached by overrideAttrs.
# Instead we re-derive `version` + `src` from a local copy of the 2.1.212
# manifest and let the rest of the derivation (installPhase, versionCheckHook,
# meta) carry over unchanged. Checksums are the SHA-256 of the `claude` binary
# published at downloads.claude.ai/claude-code-releases/<version>/<platform>/claude.
{ ... }:

final: prev:

let
  manifest = {
    version = "2.1.212";
    platforms = {
      darwin-arm64.checksum = "09ecba2ab2df9b6ee5b0695e26f65dea60fb3b6af3d3542ee09f466838d1e574";
      darwin-x64.checksum = "7681a0634c89fa4474e53c0c794e992944aebf3409a7a2b87ea9f9b0194ea341";
      linux-arm64.checksum = "66e88634a8573a002702e6a9de0d80cb9bb7c9072f9e6f4486778539057dfd3c";
      linux-x64.checksum = "044a88cf3a5180776617fd3da1238dcbf9141ddec449a39cf7d2af1ac78e684e";
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
