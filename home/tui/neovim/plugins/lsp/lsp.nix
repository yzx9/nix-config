# nixvim doc: https://nix-community.github.io/nixvim/plugins/lsp/index.html
{ pkgs, lib, ... }:

let
  icons = import ../../icons.nix;
in
{
  programs.nixvim = {
    plugins.lsp = {
      enable = true;

      keymaps = {
        diagnostic = {
          "<leader>j" = {
            action = "goto_next";
            desc = "Go to next diagnostic";
          };
          "<leader>k" = {
            action = "goto_prev";
            desc = "Go to prev diagnostic";
          };
        };

        lspBuf = {
          gd = {
            action = "definition";
            desc = "Go to definition";
          };
          gD = {
            action = "references";
            desc = "Go to references";
          };
          gi = {
            action = "implementation";
            desc = "Go to implementation";
          };
          gt = {
            action = "type_definition";
            desc = "Go to type definition";
          };
          ## following line was replaced by lspsaga
          # "<leader>la" = {
          #   action = "code_action";
          #   desc = "LSP code action";
          # };
          # K = {
          #   action = "hover";
          #   desc = "LSP hover";
          # };
        };
      };

      postConfig = ''
        vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })

        vim.diagnostic.config({
          virtual_text = true,
          signs = true,
          underline = true,
          update_in_insert = true,
          severity_sort = false,
        })

        local signs = {
          Error = "${icons.DiagnosticError}",
          Warn = "${icons.DiagnosticWarn}",
          Info = "${icons.DiagnosticInfo}",
          Hint = "${icons.DiagnosticHint}",
        }
        for type, icon in pairs(signs) do
          local hl = "DiagnosticSign" .. type
          vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
        end
      '';

      servers = {
        gopls.enable = true;

        clangd.enable = true;

        nixd.enable = true;

        pyright.enable = true;

        html.enable = true;
        cssls.enable = true;
        # additional configuration for volar
        # https://github.com/vuejs/language-tools?tab=readme-ov-file#hybrid-mode-configuration-requires-vuelanguage-server-version-200
        tsserver = {
          enable = true;
          filetypes = [
            "typescript"
            "javascript"
            "javascriptreact"
            "typescriptreact"
            "vue"
          ];
          extraOptions = {
            init_options = {
              plugins = [
                {
                  name = "@vue/typescript-plugin";
                  location = "${lib.getBin pkgs.vue-language-server}/lib/node_modules/@vue/language-server";
                  languages = [ "vue" ];
                }
              ];
            };
          };
        };
        #eslint.enable = true;
        volar = {
          enable = true;
          package = pkgs.vue-language-server;
        };

        jsonls.enable = true;
        yamlls.enable = true;

        # dockerls.enable = true;
        # docker-compose-language-service.enable = true;
        # lua-ls.enable = true;
        # nginx-language-server.enable = true;

        typos-lsp = {
          enable = true;
          extraOptions.init_options.diagnosticSeverity = "Hint";
        };
      };
    };

    colorschemes.catppuccin.settings.integrations.native_lsp.enabled = true;
  };
}
