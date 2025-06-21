# Highlight colors for neovim
# homepage: https://github.com/brenoprata10/nvim-highlight-colors
# nixvim doc: https://nix-community.github.io/nixvim/plugins/highlight-colors/index.html
{ icons, ... }:

{
  plugins.highlight-colors = {
    enable = true;

    # https://github.com/brenoprata10/nvim-highlight-colors#options
    settings = {
      render = "virtual";
      virtual_symbol = "${icons.FileModified}";
      virtual_symbol_position = "eow";
      virtual_symbol_prefix = " ";
      virtual_symbol_suffix = "";
    };
  };

  keymaps = [
    {
      mode = "n";
      key = "<leader>uc";
      action = "<cmd>HighlightColors Toggle<cr>";
      options.desc = "Toggle color highlight";
    }
  ];
}
