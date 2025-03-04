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
            extraDescription = ''
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
      ./utils.nix

      # Plugins provide additional features
      plugins-extra/autopairs.nix
      plugins-extra/cmp.nix
      plugins-extra/copilot.nix
      plugins-extra/fidget.nix
      plugins-extra/illuminate.nix
      plugins-extra/lazygit.nix
      plugins-extra/telescope.nix
      plugins-extra/toggleterm.nix
      plugins-extra/which-key.nix
      plugins-extra/yazi.nix

      # Plugins provide LSP features, can be disabled by `lsp.enable = false;`
      plugins-lsp/comment.nix
      plugins-lsp/conform.nix
      # plugins-lsp/dap.nix # need more exploration
      plugins-lsp/lsp.nix
      plugins-lsp/lspsage.nix
      # plugins-lsp/neotest.nix # need more exploration
      plugins-lsp/treesitter.nix
      plugins-lsp/ts-autotag.nix
      plugins-lsp/ts-context-commentstring.nix

      # Plugins enhance UI
      plugins-ui/btw.nix
      plugins-ui/bufferline.nix
      plugins-ui/gitsigns.nix
      plugins-ui/indent-blankline.nix
      plugins-ui/lualine.nix
      plugins-ui/nvim-highlight-colors.nix
      plugins-ui/nvim-ufo.nix
      plugins-ui/todo-comments.nix
      plugins-ui/web-devicon.nix
    ];
  };

  # You can use `extraSpecialArgs` to pass additional arguments to your module files
  extraSpecialArgs = {
    icons = import ./icons.nix;
  };
}
