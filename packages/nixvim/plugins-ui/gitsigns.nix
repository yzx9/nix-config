# Git integration for buffers
# homepage: https://github.com/lewis6991/gitsigns.nvim
# nixvim doc: https://nix-community.github.io/nixvim/plugins/gitsigns/index.html
{ icons, ... }:

{
  plugins.gitsigns = {
    enable = true;

    settings = {
      # Show line blame with custom text
      current_line_blame = false;
      current_line_blame_formatter = " <author>, <author_time:%R> – <summary>";
      current_line_blame_formatter_nc = " Uncommitted";
      current_line_blame_opts.ignore_whitespace = true;

      # Use same icon for all signs (only color matters)
      signs = {
        add.text = icons.GitSign;
        change.text = icons.GitSign;
        changedelete.text = icons.GitSign;
        delete.text = icons.GitSign;
        topdelete.text = icons.GitSign;
        untracked.text = icons.GitSign;
      };
    };
  };

  # Enable catppuccin colors
  # https://github.com/catppuccin/nvim/blob/main/lua/catppuccin/groups/integrations/gitsigns.lua
  colorschemes.catppuccin.settings.integrations.gitsigns = true;

  # Enable lspsaga code action integrations
  plugins.lspsaga.settings.code_action.extend_git_signs = true;
}
