final: prev:

{
  # Backport of #553954 ("yazi: wrap ya with runtime dependencies", merged as
  # 73ba35da55b44b9f3f7638f29eb38c49cc7ce0fb), which our nixpkgs pin
  # f4b6996c4e8b9ee06ce147ec344c885f51071b14 predates.
  #
  # `ya env` resolves dependency executables through PATH, but the wrapped
  # package only symlinked the unwrapped `ya` binary — so the packaged
  # optional and extra dependencies (jq, _7zz, ffmpeg, ...) were invisible
  # to it (#553881). The fix wraps `ya` with the same runtime path as `yazi`.
  #
  # The change lives in the packaging expression, not the source, so the
  # whole (two-line-different) package.nix is vendored into ./yazi/ and
  # re-called here. overrideAttrs can't express it: runtimePaths stay
  # parameterized for home-manager's `.override { extraPackages = ... }`,
  # which home/yazi.nix relies on.
  #
  # TODO(yazi): drop once our nixpkgs pin contains 73ba35da.
  yazi = final.callPackage ./package.nix { };
}
