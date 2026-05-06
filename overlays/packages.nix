inputs:

final: prev:

let
  callYzx9Packages = import ../packages/callPackages.nix inputs;
  system = final.stdenv.hostPlatform.system;
in
{
  yzx9 = callYzx9Packages final.pkgs system;
}
