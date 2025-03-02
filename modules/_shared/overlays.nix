{
  nixpkgs.overlays = [
    (final: prev: {
      # workaround with NixOS/nixpkgs#375907
      qemu = prev.qemu.overrideAttrs (
        _finalAttrs: previousAttrs: {
          patches =
            previousAttrs.patches
            ++ prev.lib.optional prev.stdenvNoCC.targetPlatform.isDarwin (
              prev.fetchpatch {
                name = "fix-sme-darwin.patch";
                url = "https://github.com/utmapp/UTM/raw/acbf2ba8cd91f382a5e163c49459406af0b462b7/patches/qemu-9.1.0-utm.patch";
                hash = "sha256-S7DJSFD7EAzNxyQvePAo5ZZyanFrwQqQ6f2/hJkTJGA=";
              }
            );
        }
      );
    })
  ];
}
