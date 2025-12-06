# Not UFO in the sky, but an ultra fold in Neovim.
# homepage: https://github.com/kevinhwang91/nvim-ufo
# nixvim doc: https://nix-community.github.io/nixvim/plugins/nvim-ufo/index.html
{
  plugins.nvim-ufo = {
    enable = true;

    settings = {
      provider_selector = ''
        function(bufnr, filetype, buftype)
          local ftMap = {
            vim = "indent",
            python = {"indent"},
            git = ""
          }

         return ftMap[filetype] or { "treesitter", "indent" }
        end
      '';

      preview.mappings = {
        scrollB = "<c-b>";
        scrollD = "<c-d>";
        scrollF = "<c-f>";
        scrollU = "<c-u>";
      };
    };
  };

  # Enable catppuccin colors
  # https://github.com/catppuccin/nvim/blob/main/lua/catppuccin/groups/integrations/ufo.lua
  colorschemes.catppuccin.settings.integrations.ufo = true;

  keymaps = [
    {
      mode = "n";
      key = "zR";
      action.__raw = "require('ufo').openAllFolds";
      options.desc = "Open all folds";
    }

    {
      mode = "n";
      key = "zM";
      action.__raw = "require('ufo').closeAllFolds";
      options.desc = "Close all folds";
    }

    # https://github.com/AstroNvim/AstroNvim/blob/v4.7.7/lua/astronvim/plugins/nvim-ufo.lua#L15
    {
      mode = "n";
      key = "zp";
      action.__raw = "require('ufo').peekFoldedLinesUnderCursor";
      options.desc = "Peek fold";
    }
  ];
}
