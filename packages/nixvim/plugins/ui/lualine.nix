# A blazing fast and easy to configure neovim statusline plugin written in pure lua.
# homepage: https://github.com/nvim-lualine/lualine.nvim
# nixvim doc: https://nix-community.github.io/nixvim/plugins/lualine/index.html
{ icons, ... }:

{
  plugins.lualine = {
    enable = true;
    settings = {
      globalstatus = true;
      disabledFiletypes = {
        statusline = [
          "dashboard"
          "alpha"
          "starter"
          "Starter"
        ];
      };
      theme = {
        normal = {
          a = {
            bg = "#b4befe";
            fg = "#1c1d21";
          };
          b.bg = "nil";
          c.bg = "nil";
          y.bg = "nil";
          z.bg = "nil";
        };
      };
      sections = {
        lualine_a = [
          {
            __unkeyed-1 = "mode";
            fmt = "string.lower";
          }
        ];
        lualine_b = [
          {
            __unkeyed-1 = "branch";
            icon = icons.GitBranch; # 
          }
          "diff"
          {
            __unkeyed-1 = "diagnostic";
            symbols = {
              error = icons.DiagnosticError; # " "
              warn = icons.DiagnosticWarn; # " "
              info = icons.DiagnosticInfo; # " "
              hint = icons.DiagnosticHint; # "󰝶 "
            };
          }
        ];
        lualine_c = [
          {
            __unkeyed-1 = "filename";
            symbols = {
              modified = icons.FileModified; # " "
              readonly = "";
              unnamed = "";
            };
            separator.left = "";
          }
        ];
        lualine_x = [
          "encoding"
          "fileformat"
          {
            __unkeyed-1 = "filetype";
            icon_only = true;
          }
        ];
        lualine_y = [ "progress" ];
        lualine_z = [ "location" ];
      };
    };
  };
}
