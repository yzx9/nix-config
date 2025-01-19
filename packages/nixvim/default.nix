{
  pkgs,
  nixvim,
  ...
}:

let
  inherit (pkgs) lib;
in
nixvim.makeNixvimWithModule {
  inherit pkgs;

  module = {
    imports = [
      {
        options = {
          httpProxy = lib.mkOption {
            type = with lib.types; nullOr str;
            default = null;
            description = "httpProxy";
          };

          lsp.enable = lib.mkEnableOption "Enable LSP";
        };
      }

      ./config
      ./plugins
      ./utils.nix
    ];
  };

  # You can use `extraSpecialArgs` to pass additional arguments to your module files
  extraSpecialArgs = {
    icons = import ./icons.nix;
  };
}
