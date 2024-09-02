# simple terminal UI for git commands
# homepage: https://github.com/jesseduffield/lazygit
# nixvim doc: https://nix-community.github.io/nixvim/plugins/lazygit/index.html
{ ... }:

{
  plugins.lazygit = {
    enable = true;
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
