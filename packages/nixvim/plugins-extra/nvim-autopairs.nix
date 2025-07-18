# Autopairs for neovim written in lua
# Homepage: https://github.com/windwp/nvim-autopairs
{ config, ... }:

{
  plugins.nvim-autopairs = {
    enable = true;

    # Config (taken from AstroNvim)
    # https://github.com/AstroNvim/AstroNvim/blob/v4.7.7/lua/astronvim/plugins/autopairs.lua#L14-L25
    settings = {
      check_ts = config.lsp.enable;
      ts_config.java = false;
      fast_wrap = {
        pattern.__raw = "([[ [%'%\"%)%>%]%)%}%,] ]]):gsub(\"%s+\", \"\")";
        offset = 0;
        end_key = "$";
        check_comma = true;
        highlight = "PmenuSel";
        highlight_grey = "LineNr";
      };
    };
  };

  # With cmp integration
  # https://github.com/AstroNvim/AstroNvim/blob/v4.7.7/lua/astronvim/plugins/configs/nvim-autopairs.lua#L10
  extraConfigLua = ''
    require("cmp").event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done { tex = false })
  '';
}
