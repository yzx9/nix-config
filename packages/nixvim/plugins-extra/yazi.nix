# File Browser extension for telescope.nvim
# homepage: https://github.com/mikavilpas/yazi.nvim
# NixVim doc: https://nix-community.github.io/nixvim/plugins/yazi/index.html
{
  plugins.yazi = {
    enable = true;
    lazyLoad.settings.cmd = "Yazi";
  };

  # Yazi will automatically apply your configuration if you are using the
  # default configuration directory (~/.config/yazi). This is the default
  # behavior of home-manager for `program.yazi`.
  dependencies.yazi.enable = true;

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
