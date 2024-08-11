# A blazing fast and easy to configure neovim statusline plugin written in pure lua.
# homepage: https://github.com/nvim-lualine/lualine.nvim
# nixvim doc: https://nix-community.github.io/nixvim/plugins/lualine/index.html
{ ... }:

let
  icons = import ../../icons.nix;
in
{
  programs.nixvim.plugins.lualine = {
    enable = true;
    globalstatus = true;
    disabledFiletypes = {
      statusline = [
        "dashboard"
        "alpha"
        "starter"
      ];
    };
    theme = {
      normal = {
        a = {
          bg = "#b4befe";
          fg = "#1c1d21";
        };
        b = {
          bg = "nil";
        };
        c = {
          bg = "nil";
        };
        z = {
          bg = "nil";
        };
        y = {
          bg = "nil";
        };
      };
    };
    sections = {
      lualine_a = [
        {
          name = "mode";
          fmt = "string.lower";
        }
      ];
      lualine_b = [
        {
          name = "branch";
          icon = icons.GitBranch; # 
        }
        "diff"
      ];
      lualine_c = [
        {
          name = "diagnostic";
          extraConfig = {
            symbols = {
              error = icons.DiagnosticError; # " "
              warn = icons.DiagnosticWarn; # " "
              info = icons.DiagnosticInfo; # " "
              hint = icons.DiagnosticHint; # "󰝶 "
            };
          };
        }
      ];
      lualine_x = [
        {
          name = "filetype";
          extraConfig = {
            icon_only = true;
          };
        }
      ];
      lualine_y = [
        {
          name = "filename";
          extraConfig = {
            symbols = {
              modified = icons.FileModified; # " "
              readonly = "";
              unnamed = "";
            };
          };
          separator.left = "";
        }
      ];
      lualine_z = [ { name = "location"; } ];
    };
  };
}
