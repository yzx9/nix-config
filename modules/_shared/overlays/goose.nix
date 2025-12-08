final: prev:

let
  version = "1.15.0";

  src = prev.fetchFromGitHub {
    owner = "block";
    repo = "goose";
    tag = "v${version}";
    hash = "sha256-i9BMq9PPwTGfhSAbDrck+B74g14U+8uYOmpfN5xeyis=";
  };
in
{
  goose-cli = prev.goose-cli.overrideAttrs {
    inherit version src;

    cargoDeps = final.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-V6Vf6YzCNDwMlLFHICianR6f6zz7fEbm7+1Qeel3GDI=";
    };
  };
}
