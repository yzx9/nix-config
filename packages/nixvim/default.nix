{
  system,
  pkgs,
  nixvim,
  ...
}:

let
  nixvim' = nixvim.legacyPackages.${system};
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
        inherit minimize;
      };
    };
in
{
  nixvim = mkNixvim { minimize = false; };
  nixvim-mini = mkNixvim { minimize = true; };
}
