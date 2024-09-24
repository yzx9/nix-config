{
  config,
  pkgs,
  lib,
  ...
}@args:

let
  cfg = config.tui.editor;

  files =
    [
      ui/btw.nix
      ui/bufferline.nix
      ui/dressing.nix
      ui/gitsigns.nix
      ui/indent-blankline.nix
      ui/lualine.nix
      ui/neo-tree.nix
      ui/nvim-highlight-colors.nix
      ui/nvim-ufo.nix
      ui/todo-comments.nix
      ui/web-devicon.nix
      ux/autopairs.nix
      ux/cmp.nix
      ux/copilot.nix
      ux/fidget.nix
      ux/illuminate.nix
      ux/lazygit.nix
      ux/telescope.nix
      ux/toggleterm.nix
      ux/which-key.nix
    ]
    ++ lib.optionals cfg.lsp.enable [
      lsp/comment.nix
      lsp/conform.nix
      lsp/dap.nix
      lsp/lsp.nix
      lsp/lspsage.nix
      lsp/treesitter.nix
      lsp/ts-autotag.nix
      lsp/ts-context-commentstring.nix
    ];
in
{
  programs.nixvim = lib.mkMerge (
    map (
      file:
      let
        plugin = import file args;
      in
      plugin
    ) files
  );
}
