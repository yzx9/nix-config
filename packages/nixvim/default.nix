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
            description = ''
              Yazi will automatically apply your configuration if you are using the
              default configuration directory (~/.config/yazi). This is the default
              behavior of home-manager for `program.yazi`.

              However, `pkgs.yazi.{plugins,settings,initlua,favors}` will set a
              different configuration directory, you have to set a yazi package in
              this case
            '';
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
