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

  # Backport of git.yazi's new-fetcher-API rework (yazi-rs/plugins
  # f6f26ae04 "simplify with new fetcher API" + efa4d79d "separate staged
  # and unstaged modified states") for our yazi 26.8.15. The pinned plugin
  # (b9598e6c, 2026-08-03) predates the runner change from
  # sxyazi/yazi#4234/#4235, where a plugin fetcher must return a
  # coroutine instead of a plain `true`/`false`/`Err` — with the old
  # plugin yazi dies with "error converting Lua boolean to function".
  #
  # Note efa4d79d splits the `modified` state into `staged`/`unstaged`
  # (new theme keys); old flavors fall back to the built-in styles.
  #
  # TODO(yazi): drop once our nixpkgs pin has a yaziPlugins.git newer
  # than 2026-08-18 (master currently has 3f2b8822, 2026-08-12, which
  # still carries the transitional `fetch_compact` shim).
  yaziPlugins = prev.yaziPlugins // {
    git = prev.yaziPlugins.git.overrideAttrs (old: {
      version = "0-unstable-2026-08-20";
      src = final.fetchFromGitHub {
        owner = "yazi-rs";
        repo = "plugins";
        rev = "4848aac40731a852a5c39661037aec0d41eb7391";
        hash = "sha256-Fk7ThRbYCu9DW7TS1jAkX0y8buoinprBB/TWI5vqhx8=";
      };
    });
  };
}
