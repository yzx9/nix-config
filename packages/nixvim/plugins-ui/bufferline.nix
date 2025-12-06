# A snazzy bufferline for Neovim
# homepage: https://github.com/akinsho/bufferline.nvim
# nixvim doc: https://nix-community.github.io/nixvim/plugins/bufferline/index.html
{
  plugins.bufferline = {
    enable = true;

    settings.highlights.__raw = ''require("catppuccin.special.bufferline").get_theme()'';

    lazyLoad.settings.lazy = true; # Lazy load manually
  };

  # Enable catppuccin colors
  colorschemes.catppuccin.lazyLoad.settings.after.__raw = ''
    function()
      -- local mocha = require("catppuccin.palettes").get_palette "mocha"
      -- bufferline.setup {
      --   highlights = require("catppuccin.special.bufferline").get_theme()
      -- }
      require('lz.n').trigger_load("bufferline.nvim")
    end
  '';

  keymaps = [
    {
      mode = "n";
      key = "<S-h>";
      action = "<cmd>BufferLineCyclePrev<cr>";
      options = {
        desc = "Cycle to previous buffer";
      };
    }

    {
      mode = "n";
      key = "<S-l>";
      action = "<cmd>BufferLineCycleNext<cr>";
      options = {
        desc = "Cycle to next buffer";
      };
    }
  ];
}
