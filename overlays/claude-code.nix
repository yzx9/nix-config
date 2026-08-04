# Pin claude-code to 2.1.221.
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
    version = "2.1.221";
    platforms = {
      darwin-arm64.checksum = "7a181f36ed0fc4fbac6cee4ecf2b615eff93d8b434221fff5d7c878dc5ebf380";
      darwin-x64.checksum = "f408b9f7e46439f6e34a3687ff67433fc6bc189f40220ce4f0a1e829e58f0a52";
      linux-arm64.checksum = "d3c59d6bcc4adcf4cd85abca3bc13fa1131a34cb32f982bdf030d83a3b11e700";
      linux-x64.checksum = "60db8e88d42c24b5199c92cfd56ec88370c510c3789c6f364af748354f087ada";
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
