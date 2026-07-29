final: prev:

# Kitty ships a macOS `.app` bundle, but nixpkgs only ad-hoc signs the individual
# Mach-O executables via `darwin.autoSignDarwinBinariesHook`. macOS requires a
# whole-bundle code signature for `UNUserNotificationCenter` to deliver
# notifications — without it, kitty's desktop notifications (OSC 99, the
# `notify_on_cmd_start` / `notify_on_cmd_finish` / bell paths) are silently
# dropped with the same "application must be code-signed" error as wezterm.
#
# This mirrors the fix landed for wezterm in NixOS/nixpkgs#546589 (motivating
# bug #545211): add `rcodesign` and sign the `.app` in `postFixup`. Drop this
# overlay once nixpkgs does the same for kitty.
prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
  kitty = prev.kitty.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
      final.rcodesign
    ];

    postFixup = (old.postFixup or "") + ''
      rcodesign sign "$out/Applications/kitty.app"
    '';
  });
}
