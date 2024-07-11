# Use treesitter to auto close and auto rename html tag 
# homepage: https://github.com/windwp/nvim-ts-autotag
# nixvim doc: https://nix-community.github.io/nixvim/plugins/ts-autotag.html
{ ... }:

{
  programs.nixvim.plugins.ts-autotag = {
    enable = true;
  };
}
