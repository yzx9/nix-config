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
    version = "2.1.237";
    platforms = {
      darwin-arm64.checksum = "338901351d4ff17495738c67fc3e12a32c1b506738ac5e012eb782d3d8b5be43";
      darwin-x64.checksum = "9f00789754a7b95febc6d4e37a3b6523d4d9c4c2333a2ce4bd596ad82186224e";
      linux-arm64.checksum = "a701cfb6bb4703abc6f3ce47508c878ca8158ebdbeacd5c35c7d510c7bc70177";
      linux-x64.checksum = "73975167f0108693cf6fd6614994781657ebb8456ebef5d247458734abfb3916";
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
