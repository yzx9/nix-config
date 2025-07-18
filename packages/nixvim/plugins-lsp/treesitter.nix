{ config, lib, ... }:

lib.mkIf config.lsp.enable {
  plugins.treesitter = {
    enable = true;

    settings = {
      highlight = {
        enable = true;
        # TODO
        additional_vim_regex_highlighting = false;
      };
    };
  };

  # Enable catppuccin colors
  # https://github.com/catppuccin/nvim/blob/main/lua/catppuccin/groups/integrations/treesitter.lua
  colorschemes.catppuccin.settings.integrations.treesitter.enabled = config.plugins.treesitter.enable;
}
