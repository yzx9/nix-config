{
  stdenv,
  fetchurl,
  cmake,
  ...
}:

let
  version = "11.0.0";
  versionParts = builtins.splitVersion version;
  majorVersion = builtins.elemAt versionParts 0;
  minorVersion = builtins.elemAt versionParts 1;
  majorMinorVersion = "${majorVersion}.${minorVersion}";
in
stdenv.mkDerivation rec {
  pname = "openmesh";
  inherit version;

  src = fetchurl {
    url = "https://www.openmesh.org/media/Releases/${majorMinorVersion}/OpenMesh-${version}.tar.gz";
    sha256 = "sha256-x/NdKWc+bbttZbIUwQxMYklSGo8ej4226L3C7teYrtw=";
  };

  buildInputs = [ cmake ];
}
