# An extensible framework for interacting with tests within NeoVim.
# homepage: https://github.com/nvim-neotest/neotest
# nixvim doc: https://nix-community.github.io/nixvim/plugins/neotest/index.html
{ config, ... }:

{
  plugins.neotest = {
    enable = config.lsp.enable;

    adapters = {
      python.enable = true;
    };
  };
}
