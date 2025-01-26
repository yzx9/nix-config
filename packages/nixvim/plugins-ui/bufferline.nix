# A snazzy bufferline for Neovim
# homepage: https://github.com/akinsho/bufferline.nvim
# nixvim doc: https://nix-community.github.io/nixvim/plugins/bufferline/index.html
{
  plugins.bufferline = {
    enable = true;
  };

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
