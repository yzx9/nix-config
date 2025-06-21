# Highlight colors for neovim
# homepage: https://github.com/brenoprata10/nvim-highlight-colors
{ pkgs, icons, ... }:

{
  extraPlugins = [ pkgs.vimPlugins.nvim-highlight-colors ];

  # https://github.com/brenoprata10/nvim-highlight-colors#options
  extraConfigLua = ''
    require("nvim-highlight-colors").setup({
      render = "virtual",
      virtual_symbol = "${icons.FileModified}",
      virtual_symbol_position = "eow",
      virtual_symbol_prefix = " ",
      virtual_symbol_suffix = "",
    })
  '';

  keymaps = [
    {
      mode = "n";
      key = "<leader>uc";
      action = "<cmd>HighlightColors Toggle<cr>";
      options.desc = "Toggle color highlight";
    }
  ];
}
