final: prev: {
  fish = prev.fish.overrideAttrs (oldAttrs: {
    # disable darwin pending https://github.com/NixOS/nixpkgs/pull/462090 getting through staging
    doCheck = !prev.stdenv.hostPlatform.isDarwin;
  });
}
