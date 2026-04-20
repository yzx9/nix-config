# Performant, batteries-included completion plugin for Neovim
# homepage: https://github.com/saghen/blink.cmp
# nixvim doc: https://nix-community.github.io/nixvim/plugins/blink-cmp/index.html
{ config, lib, ... }:

{
  plugins.blink-cmp = {
    enable = true;

    settings = {
      keymap = {
        preset = "default";
        "<Tab>" = [
          "select_next"
          "fallback"
        ];
        "<CR>" = [
          "accept"
          "fallback"
        ];
      };

      snippets.preset = "default";

      sources = {
        default = [
          "lsp"
          "path"
          "snippets"
          "buffer"
        ];

        per_filetype.gitcommit = [ "buffer" ];

        providers = {
          path.score_offset = 3;

          buffer = {
            score_offset = -3;
            min_keyword_length = 3;
          };
        }
        // lib.mkIf config.lsp.enable {
          lsp = {
            name = "LSP";
            module = "blink.cmp.sources.lsp";
            fallbacks = [ "buffer" ];
          };
        };
      };

      cmdline = {
        enabled = true;
        keymap.preset = "cmdline";

        completion = {
          list.selection.preselect = true;
          ghost_text.enabled = true;
        };
      };

      completion = {
        documentation = {
          auto_show = true;
          window.border = "solid";
        };

        menu.border = "solid";
        list.selection.preselect = false;
        accept.auto_brackets.enabled = true;
      };
    };
  };
}
