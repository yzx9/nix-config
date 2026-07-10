{ ... }:

final: prev:

let
  # Backport of NixOS/nixpkgs#539470 (2.1.202 → 2.1.204) and #539827
  # (2.1.204 → 2.1.205). Our nixpkgs pin (f205b557) ships 2.1.201, and neither
  # bump has reached nixpkgs-unstable yet.
  #
  # claude-code's version and per-platform binary checksum live in a manifest
  # (pkgs/by-name/cl/claude-code/manifest.json) that package.nix reads via
  # lib.importJSON — a `let` binding, so it can't be reached by overrideAttrs.
  # Instead we re-derive `version` + `src` from a local copy of the 2.1.205
  # manifest and let the rest of the derivation (installPhase, versionCheckHook,
  # meta) carry over unchanged. Checksums are the SHA-256 of the `claude` binary
  # published at downloads.claude.ai/claude-code-releases/<version>/<platform>/claude.
  manifest = {
    version = "2.1.205";
    platforms = {
      darwin-arm64.checksum = "33e28624c5ae84f2bd7d2d8761e5d2e77997ba965cb11b6448de6b6e2c566f9c";
      darwin-x64.checksum = "4299a3f48551ef365f2d056f24d87e84b822c4c10b6acc46979446b7b5c60ceb";
      linux-arm64.checksum = "c1874c85bcd3a88b70439fd50ff5910b7e6ac5371c14dd49d4ccc2878a592d09";
      linux-x64.checksum = "dd8734c0b6a503fe1d17425184e57b397c30bb0337a33f1470d9985febfe5b09";
    };
  };
  platformKey = "${final.stdenv.hostPlatform.node.platform}-${final.stdenv.hostPlatform.node.arch}";
  entry =
    manifest.platforms.${platformKey}
      or (throw "claude-code overlay has no 2.1.205 checksum for ${platformKey}");
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
