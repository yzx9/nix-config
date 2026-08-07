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
    version = "2.1.224";
    platforms = {
      darwin-arm64.checksum = "391df9d2ab04e4cf32199335720ac7715a582e91eaecfd4d2198a16f57ea59b3";
      darwin-x64.checksum = "7ae17a768a7270c7bd6c5484587c3c650dff425b4beeeb03addc1f2a4a7d702a";
      linux-arm64.checksum = "3e50836e227868746273653e0f8115cf5fc9cb34a081847c6040c81d80812c33";
      linux-x64.checksum = "a2b5add7dc4bcd8eaa029f4e8bdac4df7769b4073698db7989d206baf9419c2d";
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
