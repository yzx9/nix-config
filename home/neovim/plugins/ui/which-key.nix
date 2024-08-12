# Create key bindings that stick. WhichKey is a lua plugin for Neovim 0.5 that displays a popup with possible keybindings of the command you started typing.
# homepage: https://github.com/folke/which-key.nvim
# nixvim doc: https://nix-community.github.io/nixvim/plugins/which-key/index.html
{ ... }:

let
  icons = import ../../icons.nix;
in
{
  programs.nixvim = {
    plugins.which-key = {
      enable = true;

      settings = {
        delay = 200;
        expand = 1;
        notify = false;
        preset = false;

        # icons.group = "";
        win.border = "single";

        # Disable which-key when in some plugins
        disable.ft = [
          "TelescopePrompt"
          "neo-tree"
          "neo-tree-popup"
          "lazygit"
        ];

        # Customize section names (prefixed mappings)
        spec = [
          {
            __unkeyed-1 = "<leader>b";
            icon = icons.Tab;
            group = "Buffers";
          }
          {
            __unkeyed-1 = "<leader>bs";
            icon = icons.Sort;
            group = "Sort Buffers";
          }
          {
            __unkeyed-1 = "<leader>d";
            icon = icons.Debugger;
            group = "Debugger";
          }
          {
            __unkeyed-1 = "<leader>f";
            icon = icons.Search;
            group = "Find";
          }
          {
            __unkeyed-1 = "<leader>g";
            icon = icons.ArrowRight;
            group = "Go";
          }
          {
            __unkeyed-1 = "<leader>l";
            icon = icons.ActiveLSP;
            group = "Language Tools";
          }
          {
            __unkeyed-1 = "<leader>s";
            icon = icons.Session;
            group = "Session";
          }
          {
            __unkeyed-1 = "<leader>t";
            icon = icons.Terminal;
            group = "Terminal";
          }
          {
            __unkeyed-1 = "<leader>u";
            icon = icons.Window;
            group = "UI/UX";
          }
        ];
      };

    };

    # Enable catppuccin colors
    # https://github.com/catppuccin/nvim/blob/main/lua/catppuccin/groups/integrations/which_key.lua
    colorschemes.catppuccin.settings.integrations.which_key = true;
  };
}
