# Neovim treesitter plugin for setting the commentstring based on the cursor location in a file.
# homepage: https://github.com/JoosepAlviste/nvim-ts-context-commentstring
# nixvim doc: https://nix-community.github.io/nixvim/plugins/ts-context-commentstring.html
{ ... }:

{
  programs.nixvim.plugins.ts-context-commentstring = {
    enable = true;
  };
}
