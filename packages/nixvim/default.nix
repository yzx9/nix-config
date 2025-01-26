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
          lsp.enable = lib.mkEnableOption "Enable LSP";

          httpProxy = lib.mkOption {
            type = with lib.types; nullOr str;
            default = null;
            description = "httpProxy";
          };

          yazi.package = lib.mkPackageOption pkgs "yazi" {
            nullable = true;
          };
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
