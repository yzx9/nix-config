# Pin claude-code.
#
# claude-code's version and per-platform binary checksum live in a manifest
# (pkgs/by-name/cl/claude-code/manifest.json) that package.nix reads via
# lib.importJSON — a `let` binding, so it can't be reached by overrideAttrs.
# Instead we re-derive `version` + `src` from a local copy manifest and let
# the rest of the derivation (installPhase, versionCheckHook, meta) carry
# over unchanged. Checksums are the SHA-256 of the `claude` binary published
# at downloads.claude.ai/claude-code-releases/<version>/<platform>/claude.
final: prev:

let
  manifest = {
    version = "2.1.223";
    platforms = {
      darwin-arm64.checksum = "fcbe0b8d47570c501302dd1ad31cc26ac2810f022c45fa253936a6961dee32bf";
      darwin-x64.checksum = "350e657428a6d34f7cf71f6738c5ebb6a1952ccb12fc1747f64297e065b1846f";
      linux-arm64.checksum = "60e83d8db0e894d0e54413e5e7daa256d180db660f51e139a51b614fc30cf3ac";
      linux-x64.checksum = "98226474f802e3094d6a86c5ade8883c16206d0fcb5c400b7401c800063e99d7";
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
