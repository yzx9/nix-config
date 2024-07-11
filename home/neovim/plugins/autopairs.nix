# Autopairs for neovim written in lua 
# Homepage: https://github.com/windwp/nvim-autopairs
{ pkgs, ... }:

{
  programs.nixvim = {
    extraPlugins = [ pkgs.vimPlugins.nvim-autopairs ];

    # Config (taken from AstroNvim)
    # https://github.com/AstroNvim/AstroNvim/blob/v4.7.7/lua/astronvim/plugins/autopairs.lua#L14-L25
    # With cmp integration
    # https://github.com/AstroNvim/AstroNvim/blob/v4.7.7/lua/astronvim/plugins/configs/nvim-autopairs.lua#L10
    extraConfigLua = ''
      require("nvim-autopairs").setup({
        check_ts = true,
        ts_config = { java = false },
        fast_wrap = {
          map = "<M-e>",
          chars = { "{", "[", "(", '"', "'" },
          pattern = ([[ [%'%"%)%>%]%)%}%,] ]]):gsub("%s+", ""),
          offset = 0,
          end_key = "$",
          keys = "qwertyuiopzxcvbnmasdfghjkl",
          check_comma = true,
          highlight = "PmenuSel",
          highlight_grey = "LineNr",
        },
      })

      require("cmp").event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done { tex = false })
    '';

    keymaps = [
      {
        mode = "n";
        key = "<leader>ua";
        action.__raw = "function() require('astrocore.toggles').autopairs() end";
        options.desc = "Toggle autopairs";
      }
    ];
  };
}
