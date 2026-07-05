{ nixpkgs, ... }:

final: prev:

# Linux is unaffected: nixpkgs' zotero ships a properly-installed bundle there.
nixpkgs.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
  # nixpkgs' zotero ships an unsigned .app on darwin. Its upstream `app/build.sh`
  # is designed to codesign every dylib + the main bundle with a `$DEVELOPER_ID`,
  # but nixpkgs builds without one, so the whole signing block is skipped and the
  # bundled firefox-esr Mach-Os (XUL, libmozglue, ...) keep stale signatures.
  # macOS 26 (Tahoe) tightened enforcement and SIGKILLs the app on launch
  # ("Code Signature Invalid" / "Invalid Page").
  #
  # We re-sign ad-hoc with `rcodesign`: Apple's `codesign` chokes on the ~194MB
  # `XUL` with "internal error in Code Signing subsystem", while rcodesign signs
  # it in under a second and produces a signature `codesign -vvv` fully validates.
  # `$out/bin/zotero` is a 3-line bash wrapper that re-execs the signed main
  # binary, so it needs no signing of its own (and rcodesign rejects scripts
  # with "specified path is not of a recognized type").
  zotero = prev.zotero.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.rcodesign ];
    postFixup = (old.postFixup or "") + ''
      ${final.lib.getExe final.rcodesign} sign $out/Applications/Zotero.app
    '';
  });
}
