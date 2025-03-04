# A completion plugin for neovim coded in Lua.
# homepage: https://github.com/hrsh7th/nvim-cmp/
# nixvim doc: https://nix-community.github.io/nixvim/plugins/cmp/index.html
#
# NOTE: cmp will stop work when recording macro `q@...q`

{ config, lib, ... }:

{
  plugins = {
    cmp = {
      enable = true;
      settings = {
        autoEnableSources = true;
        # experimental = {
        #   ghost_text = true;
        # };
        performance = {
          debounce = 60;
          fetchingTimeout = 200;
          maxViewEntries = 30;
        };
        snippet = {
          expand = "luasnip";
        };
        formatting = {
          fields = [
            "kind"
            "abbr"
            "menu"
          ];
        };
        sources = [
          { name = "nvim_lsp"; }
          { name = "emoji"; }
          {
            name = "buffer"; # text within current buffer
            option.get_bufnrs.__raw = "vim.api.nvim_list_bufs";
            keywordLength = 3;
          }
          {
            name = "path"; # file system paths
            keywordLength = 3;
          }
        ];

        window = {
          completion.border = "solid";
          documentation.border = "solid";
        };

        mapping = {
          "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
          "<C-j>" = "cmp.mapping.select_next_item()";
          "<C-k>" = "cmp.mapping.select_prev_item()";
          "<C-q>" = "cmp.mapping.abort()";
          "<C-b>" = "cmp.mapping.scroll_docs(-4)";
          "<C-f>" = "cmp.mapping.scroll_docs(4)";
          "<C-Space>" = "cmp.mapping.complete()";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
          "<S-CR>" = "cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true })";
        };
      };
    };

    # nvim-cmp source for buffer words
    # homepage: https://github.com/hrsh7th/cmp-buffer/
    # nixvim doc: https://nix-community.github.io/nixvim/plugins/cmp-buffer.html
    cmp-buffer.enable = true;

    # nvim-cmp source for vim's cmp-cmd
    # homepage: https://github.com/hrsh7th/cmp-cmdline/
    # nixvim doc: https://nix-community.github.io/nixvim/plugins/cmp-cmdline.html
    cmp-cmdline.enable = false; # autocomplete for cmdline

    # nvim-cmp source for emoji
    # homepage: https://github.com/hrsh7th/cmp-emoji/
    # nixvim doc: https://nix-community.github.io/nixvim/plugins/cmp-emoji.html
    cmp-emoji.enable = true;

    # nvim-cmp source for neovim builtin LSP client
    # homepage: https://github.com/hrsh7th/cmp-nvim-lsp/
    # nixvim doc: https://nix-community.github.io/nixvim/plugins/cmp-nvim-lsp.html
    cmp-nvim-lsp.enable = true; # lsp

    # nvim-cmp source for path
    # homepage: https://github.com/hrsh7th/cmp-path/
    # nixvim doc: https://nix-community.github.io/nixvim/plugins/cmp-path.html
    cmp-path.enable = true; # file system paths
  };

  extraConfigLua =
    ''
      local cmp = require('cmp')

      -- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline({'/', "?" }, {
        sources = {
          { name = 'buffer' }
        }
      })

       -- Set configuration for specific filetype.
      cmp.setup.filetype('gitcommit', {
        sources = cmp.config.sources({
          { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
        }, {
          { name = 'buffer' },
        })
      })

      -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline(':', {
        sources = cmp.config.sources({
          { name = 'path' }
        }, {
        { name = 'cmdline' }
      }),
      -- formatting = {
      --   format = function(_, vim_item)
      --     vim_item.kind = cmdIcons[vim_item.kind] or "FOO"
      --     return vim_item
      --   end
      -- }
      })
    ''
    + lib.optionalString config.lsp.enable ''
      -- Set up lspconfig.
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      -- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
      -- NOTE: To simplify configuration, we only add some conflicted LSP here.
      require('lspconfig')['pyright'].setup {
        capabilities = capabilities
      }
    '';
}
