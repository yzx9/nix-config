# Not UFO in the sky, but an ultra fold in Neovim.
# homepage: https://github.com/kevinhwang91/nvim-ufo
# nixvim doc: https://nix-community.github.io/nixvim/plugins/nvim-ufo/index.html
{ ... }:

{
  plugins.nvim-ufo = {
    enable = true;

    preview.mappings = {
      scrollB = "<c-b>";
      scrollD = "<c-d>";
      scrollF = "<c-f>";
      scrollU = "<c-u>";
    };
  };

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
