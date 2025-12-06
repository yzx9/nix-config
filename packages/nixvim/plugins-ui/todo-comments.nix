# Highlight, list and search todo comments in your projects
# homepage: https://github.com/folke/todo-comments.nvim
# nixvim doc: https://nix-community.github.io/nixvim/plugins/todo-comments/index.html
{
  plugins.todo-comments = {
    enable = true;
    # highlight.pattern = ".*<(KEYWORDS)\s*";
    # search.pattern = "\\b(KEYWORDS)";

    lazyLoad.settings = {
      event = "DeferredUIEnter";
      keys = [
        "<leader>fT"
        "]T"
        "[T"
      ];
    };
  };

  keymaps = [
    {
      mode = "n";
      key = "<leader>fT";
      action.__raw = "function() TelescopeWithTheme('todo', {}, 'todo-comments') end";
      options.desc = "Find TODOs";
    }

    {
      mode = "n";
      key = "]T";
      action.__raw = "function() require('todo-comments').jump_next() end";
      options.desc = "Next TODO comment";
    }

    {
      mode = "n";
      key = "[T";
      action.__raw = "function() require('todo-comments').jump_prev() end";
      options.desc = "Previous TODO comment";
    }
  ];
}
