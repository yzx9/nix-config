# homepage: https://github.com/nvim-neo-tree/neo-tree.nvim
# nixvim doc: https://nix-community.github.io/nixvim/plugins/neo-tree/index.html
{ ... }:

{
  programs.nixvim.plugins.neo-tree = {
    enable = true;
  };
}
