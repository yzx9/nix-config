# Neovim plugin to improve the default vim.ui interfaces
# homepage: https://github.com/stevearc/dressing.nvim
# nixvim doc: https://nix-community.github.io/nixvim/plugins/dressing/index.html
{
  plugins.dressing = {
    enable = true;

    settings = {
      input = {
        default_prompt = "> ";
        title_pos = "center";
      };

      select.backend = [
        "telescope"
        "builtin"
      ];
    };
  };
}
