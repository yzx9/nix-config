# A snazzy bufferline for Neovim
# homepage: https://github.com/akinsho/bufferline.nvim
# nixvim doc: https://nix-community.github.io/nixvim/plugins/bufferline/index.html
{
  plugins.bufferline = {
    enable = true;

    settings.highlights.__raw = ''
      require("catppuccin.special.bufferline").get_theme()
    '';

    lazyLoad.settings.lazy = true; # Lazy load manually
  };

  # Enable catppuccin colors and trigger bufferline load after
  colorschemes.catppuccin.luaConfig.post = ''
    require('lz.n').trigger_load("bufferline.nvim")
  '';

  keymaps = [
    {
      mode = "n";
      key = "<S-h>";
      action = "<cmd>BufferLineCyclePrev<cr>";
      options.desc = "Cycle to previous buffer";
    }

    {
      mode = "n";
      key = "<S-l>";
      action = "<cmd>BufferLineCycleNext<cr>";
      options.desc = "Cycle to next buffer";
    }
  ];
}
