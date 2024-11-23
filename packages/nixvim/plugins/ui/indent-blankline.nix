# Indent guides for Neovim
# homepage: https://github.com/lukas-reineke/indent-blankline.nvim
# nixvim doc: https://nix-community.github.io/nixvim/plugins/indent-blankline/index.html
{ ... }:

{

  # https://github.com/AstroNvim/AstroNvim/blob/v4.7.7/lua/astronvim/plugins/indent-blankline.lua#L15-L41
  plugins.indent-blankline = {
    enable = true;

    settings = {
      indent.char = "▏";

      # Disable scope highlighting
      scope.enabled = false;

      exclude.filetypes = [
        "aerial"
        "alpha"
        "dashboard"
        "lazy"
        "mason"
        "neo-tree"
        "NvimTree"
        "neogitstatus"
        "notify"
        "startify"
        "toggleterm"
        "Trouble"
      ];

      scope = {
        show_start = false;
        show_end = false;
      };
    };
  };

  # Enable catppuccin colors
  # https://github.com/catppuccin/nvim/blob/main/lua/catppuccin/groups/integrations/indent_blankline.lua
  colorschemes.catppuccin.settings.integrations.indent_blankline = true;
}
