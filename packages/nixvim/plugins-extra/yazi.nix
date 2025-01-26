# File Browser extension for telescope.nvim
# homepage: https://github.com/mikavilpas/yazi.nvim
# NixVim doc: https://nix-community.github.io/nixvim/plugins/yazi/index.html
{ config, ... }:

{
  plugins.yazi = {
    enable = true;
    yaziPackage = config.yazi.package;
  };

  keymaps = [
    {
      mode = "n";
      key = "<leader>o";
      action = "<cmd>Yazi toggle<CR>";
      options.desc = "Resume the last yazi session";
    }
  ];
}
