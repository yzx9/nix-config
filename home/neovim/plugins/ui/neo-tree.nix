# Neovim plugin to manage the file system and other tree like structures. 
# homepage: https://github.com/nvim-neo-tree/neo-tree.nvim
# nixvim doc: https://nix-community.github.io/nixvim/plugins/neo-tree/index.html
{ ... }:

{
  programs.nixvim = {
    plugins.neo-tree = {
      enable = true;

      # Automatically clean up broken neo-tree buffers saved in sessions
      autoCleanAfterSessionRestore = true;

      # Close Neo-tree if it is the last window left in the tab
      closeIfLastWindow = true;
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>e";
        action = "<cmd>Neotree toggle<cr>";
        options.desc = "Toggle explorer";
      }
      {
        mode = "n";
        key = "<leader>o";
        options.desc = "Toggle explorer focus";

        # https://github.com/AstroNvim/AstroNvim/blob/v4.7.7/lua/astronvim/plugins/neo-tree.lua#L12-L18
        action.__raw = ''
          function()
            if vim.bo.filetype == "neo-tree" then
              vim.cmd.wincmd "p"
            else
              vim.cmd.Neotree "focus"
            end
          end
        '';
      }
    ];
  };
}
