# Smart and powerful comment plugin for neovim. Supports treesitter, dot repeat,
# left-right/up-down motions, hooks, and more 
# homepage: https://github.com/numtostr/comment.nvim/
# nixvim doc: https://nix-community.github.io/nixvim/plugins/comment/index.html
{ ... }:

{
  plugins.comment = {
    enable = true;
    settings.pre_hook = "require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook()";
  };
}
