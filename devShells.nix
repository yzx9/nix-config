{ nixpkgs, ... }:

system:

let
  pkgs = nixpkgs.legacyPackages.${system};
in
{
  default = pkgs.mkShell {
    packages = with pkgs; [
      just

      # formatter
      prettier
      nixfmt
    ];
  };
}
