# illuminate.vim - (Neo)Vim plugin for automatically highlighting other uses of the word under the cursor using either LSP, Tree-sitter, or regex matching. 
# homepage: https://github.com/RRethy/vim-illuminate
# nixvim doc: https://nix-community.github.io/nixvim/plugins/illuminate/index.html
{ ... }:

{
  programs.nixvim = {
    plugins.illuminate = {
      enable = true;
      delay = 200;
      filetypesDenylist = [
        "dirbuf"
        "dirvish"
        "fugitive"
        "toggleterm"
      ];
      largeFileOverrides.providers = [ "lsp" ];
      minCountToHighlight = 2;

      extraOptions = {
        largeFileCutoff.__raw = "vim.tbl_get(require 'astrocore', 'config', 'features', 'large_buf', 'lines')";
        should_enable.__raw = "function(bufnr) return require('astrocore.buffer').is_valid(bufnr) end";
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "]r";
        action.__raw = "function() require('illuminate').goto_next_reference(false) end";
        options.desc = "Next reference";
      }
      {
        mode = "n";
        key = "[r";
        action.__raw = "function() require('illuminate').goto_prev_reference(false) end";
        options.desc = "Previous reference";
      }
      {
        mode = "n";
        key = "<leader>ur";
        action.__raw = "function() require('illuminate').toggle_buf() end";
        options.desc = "Toggle reference highlighting (buffer)";
      }
      {
        mode = "n";
        key = "<leader>uR";
        action.__raw = "function() require('illuminate').toggle() end";
        options.desc = "Toggle reference highlighting (global)";
      }
    ];
  };
}
