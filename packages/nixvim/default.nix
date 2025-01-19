{
  system,
  nixpkgs,
  nixvim,
  ...
}:

let
  pkgs = nixpkgs.legacyPackages.${system};
  nixvim' = nixvim.legacyPackages.${system};
  icons = import ./icons.nix;
  mkNixvim =
    { minimize }:
    nixvim'.makeNixvimWithModule {
      inherit pkgs;

      module = {
        imports = [
          ./config
          ./plugins
          ./utils.nix
        ];
      };

      # You can use `extraSpecialArgs` to pass additional arguments to your module files
      extraSpecialArgs = {
        inherit minimize icons;
      };
    };
in
{
  nixvim = mkNixvim { minimize = false; };
  nixvim-mini = mkNixvim { minimize = true; };
}
