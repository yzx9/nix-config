# Pin claude-code to 2.1.195.
#
# claude-code's version and per-platform binary checksum live in a manifest
# (pkgs/by-name/cl/claude-code/manifest.json) that package.nix reads via
# lib.importJSON — a `let` binding, so it can't be reached by overrideAttrs.
# Instead we re-derive `version` + `src` from a local copy of the 2.1.195
# manifest and let the rest of the derivation (installPhase, versionCheckHook,
# meta) carry over unchanged. Checksums are the SHA-256 of the `claude` binary
# published at downloads.claude.ai/claude-code-releases/<version>/<platform>/claude.
{ ... }:

final: prev:

let
  manifest = {
    version = "2.1.195";
    platforms = {
      darwin-arm64.checksum = "8b45adad93f336ab95f33e714494b19fd3377a494eb05c122c8677bc895876ad";
      darwin-x64.checksum = "7eb8716e6d6e6a278d13158793529336290837fca457facfec656f1b1a287c60";
      linux-arm64.checksum = "b02279999058dc80a0e1c5d39463d1545a178615492f84139aac8d61214a7e9a";
      linux-x64.checksum = "8323e70125063147a4478b957745d835a87e5e72ffd25b838ea9a841c03e6a37";
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
