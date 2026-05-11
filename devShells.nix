{ nixpkgs, ... }:

system:

let
  pkgs = nixpkgs.legacyPackages.${system};
in
{
  default = pkgs.mkShell {
    packages = with pkgs; [
      just
      jq

      # formatter
      prettier
      nixfmt
    ];
  };
}
