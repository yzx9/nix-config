# Create key bindings that stick. WhichKey is a lua plugin for Neovim 0.5 that displays a popup with possible keybindings of the command you started typing.
# homepage: https://github.com/folke/which-key.nvim
# nixvim doc: https://nix-community.github.io/nixvim/plugins/which-key/index.html
{ ... }:

let
  icons = import ../icons.nix;
in
{
  programs.nixvim = {
    plugins.which-key = {
      enable = true;
      icons.group = "";
      window.border = "single";

      # Disable which-key when in neo-tree or telescope
      disable.filetypes = [
        "TelescopePrompt"
        "neo-tree"
        "neo-tree-popup"
      ];

      # Customize section names (prefixed mappings)
      registrations = {
        "<leader>b".name = "${icons.Tab} Buffers";
        "<leader>bs".name = "${icons.Sort} Sort Buffers";
        "<leader>d".name = "${icons.Debugger} Debugger";
        "<leader>f".name = "${icons.Search} Find";
        "<leader>g".name = "${icons.Search} Go";
        "<leader>l".name = "${icons.ActiveLSP} Language Tools";
        "<leader>m".name = " Markdown";
        "<leader>s".name = "${icons.Session} Session";
        "<leader>t".name = "${icons.Terminal} Terminal";
        "<leader>u".name = "${icons.Window} UI/UX";
      };
    };

    # Enable catppuccin colors
    # https://github.com/catppuccin/nvim/blob/main/lua/catppuccin/groups/integrations/which_key.lua
    colorschemes.catppuccin.settings.integrations.which_key = true;
  };
}
