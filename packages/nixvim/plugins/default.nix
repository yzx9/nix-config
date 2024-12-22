{
  lib,
  minimize ? false,
  ...
}:

{
  imports =
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
    ++ lib.optionals (!minimize) [
      lsp/comment.nix
      lsp/conform.nix
      # lsp/dap.nix # need more exploration
      lsp/lsp.nix
      lsp/lspsage.nix
      # lsp/neotest.nix # need more exploration
      lsp/treesitter.nix
      lsp/ts-autotag.nix
      lsp/ts-context-commentstring.nix
    ];
}
