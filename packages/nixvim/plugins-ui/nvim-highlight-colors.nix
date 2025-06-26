# Highlight colors for neovim
# homepage: https://github.com/brenoprata10/nvim-highlight-colors
# nixvim doc: https://nix-community.github.io/nixvim/plugins/highlight-colors/index.html
{ ... }:

{
  plugins.highlight-colors = {
    enable = true;

    # https://github.com/brenoprata10/nvim-highlight-colors#options
    settings.render = "background";
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
