{ ... }:

final: prev:

# terminal-notifier is darwin-only, and this is a darwin build fix, so gate on it.
prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
  # Backport of NixOS/nixpkgs#541326 — "terminal-notifier: fix darwin build".
  # The stock ld on recent darwin fails to link the bundle; using `lld` as the
  # linker via `-fuse-ld=lld` fixes it. Upstream marks these as TODO cleanup on
  # `staging`, so drop this overlay once they land in our nixpkgs pin.
  terminal-notifier = prev.terminal-notifier.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
      final.llvmPackages.lld
    ];
    env.NIX_CFLAGS_LINK = "-fuse-ld=lld";
  });
}
