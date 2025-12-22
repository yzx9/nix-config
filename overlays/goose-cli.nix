final: prev:

{
  goose-cli = prev.goose-cli.overrideAttrs (
    finalAttrs: prevAttrs: {
      version = "1.18.0";

      src = prev.fetchFromGitHub {
        owner = "block";
        repo = "goose";
        tag = "v${finalAttrs.version}";
        hash = "sha256-KlRBYklg5Rzi+gGr9IDnF9d8L+m2O+sLP/9dWaI5bCg=";
      };

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) src;
        hash = "sha256-nFdQeew6XXwd0Chq+GNJYcxZ2N6e5kYfG2KEbjI3qhc=";
      };

      # Too slow to build with check
      doCheck = false;
    }
  );
}
