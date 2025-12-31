{ self, ... }:

final: prev:

let
  system = final.stdenv.hostPlatform.system;
in
{
  yzx9 = self.packages.${system};
}
