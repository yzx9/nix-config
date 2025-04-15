# File Browser extension for telescope.nvim
# homepage: https://github.com/mikavilpas/yazi.nvim
# NixVim doc: https://nix-community.github.io/nixvim/plugins/yazi/index.html
{ config, ... }:

{
  plugins.yazi.enable = true;

  dependencies.yazi = {
    enable = true;
    package = config.yazi.package;
  };

  keymaps = [
    # -- 👇 in this section, choose your own keymappings!
    # {
    #   "<leader>-",
    #   mode = { "n", "v" },
    #   "<cmd>Yazi<cr>",
    #   desc = "Open yazi at the current file",
    # },
    # {
    #   -- Open in the current working directory
    #   "<leader>cw",
    #   "<cmd>Yazi cwd<cr>",
    #   desc = "Open the file manager in nvim's working directory",
    # },
    # {
    #   "<c-up>",
    #   "<cmd>Yazi toggle<cr>",
    #   desc = "Resume the last yazi session",
    # },

    {
      mode = "n";
      key = "<leader>o";
      action = "<cmd>Yazi<CR>";
      options.desc = "Open yazi at the current file";
    }
  ];
}
