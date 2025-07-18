# simple terminal UI for git commands
# homepage: https://github.com/kdheepak/lazygit.nvim
# nixvim doc: https://nix-community.github.io/nixvim/plugins/lazygit/index.html
# upstream: https://github.com/jesseduffield/lazygit
{
  plugins.lazygit = {
    enable = true;
    # lazyLoad.settings.cmd = "LazyGit";
  };

  extraConfigLua = ''
    require("telescope").load_extension("lazygit")
  '';

  keymaps = [
    {
      mode = "n";
      key = "<leader>gg";
      action = "<cmd>LazyGit<CR>";
      options = {
        desc = "LazyGit (root dir)";
      };
    }
  ];
}
