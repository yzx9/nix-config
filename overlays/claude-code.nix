# Pin claude-code to 2.1.215.
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
    version = "2.1.215";
    platforms = {
      darwin-arm64.checksum = "90608b5c5ab504e96e77365cea6203d046e291d59b2bb42cf28dcb2ccdf9dd58";
      darwin-x64.checksum = "1ef5f5e56ede9f7765a9bef654ece6045dba58f48b7f5b699765375953d52b6b";
      linux-arm64.checksum = "2b43a3d5b0787217e5d7381fad42c7314292546fe9db9eb8b9b379de90509b30";
      linux-x64.checksum = "c1efffaaf370aa187cb6a09dd93d4e511c646899b0078476f83791b664bde7fe";
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
