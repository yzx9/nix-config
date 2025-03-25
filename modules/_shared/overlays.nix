{ inputs, ... }:

{
  nixpkgs.overlays = [
    inputs.nur.overlays.default

    (final: prev: {
      # workaround with NixOS/nixpkgs#375907
      qemu = prev.qemu.overrideAttrs (
        _finalAttrs: previousAttrs: {
          patches =
            previousAttrs.patches
            ++ prev.lib.optional prev.stdenvNoCC.targetPlatform.isDarwin (
              prev.fetchpatch {
                name = "fix-sme-darwin.patch";
                url = "https://gitlab.com/qemu-project/qemu/-/commit/fd207677a83087454b8afef31651985a1df0d2dd.patch";
                hash = "sha256-VgY2Z+PaHGt7fIEsUPrGbk/TF5bQk5QjvlJAmJb8Eiw=";
              }
            );
        }
      );
    })
  ];
}
