# Use treesitter to auto close and auto rename html tag
# homepage: https://github.com/windwp/nvim-ts-autotag
# nixvim doc: https://nix-community.github.io/nixvim/plugins/ts-autotag.html
{ config, lib, ... }:

lib.mkIf config.lsp.enable {
  plugins.ts-autotag = {
    enable = true;
  };
}
