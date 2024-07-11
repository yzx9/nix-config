# null-ls.nvim reloaded / Use Neovim as a language server to inject LSP diagnostics, code actions, and more via Lua.  
# homepage: https://github.com/nvimtools/none-ls.nvim/
# nixvim doc: https://nix-community.github.io/nixvim/plugins/none-ls/index.html<D-s>
{ ... }:

{
  programs.nixvim.plugins.none-ls = {
    enable = true;
  };
}
