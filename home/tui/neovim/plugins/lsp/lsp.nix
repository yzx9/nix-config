# nixvim doc: https://nix-community.github.io/nixvim/plugins/lsp/index.html
{ pkgs, ... }:

let
  icons = import ../../icons.nix;
in
{
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
        ## following shortcut was replaced by lspsaga
        # gd = {
        #   action = "definition";
        #   desc = "Go to definition";
        # };
        # gD = {
        #   action = "references";
        #   desc = "Go to references";
        # };
        # gi = {
        #   action = "implementation";
        #   desc = "Go to implementation";
        # };
        # gt = {
        #   action = "type_definition";
        #   desc = "Go to type definition";
        # };
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
      # bash
      bashls.enable = true;

      # go
      gopls.enable = true;

      # c/cpp
      clangd.enable = true;
      cmake.enable = true;

      # rust
      rust-analyzer = {
        enable = true;
        installCargo = true;
        installRustc = true;
      };

      # nix
      nixd.enable = true;

      # java
      jdt-language-server.enable = true;

      # python
      pyright.enable = true;

      # frontend
      html.enable = true;
      cssls.enable = true;
      tailwindcss.enable = true;
      # additional configuration for volar
      # https://github.com/vuejs/language-tools?tab=readme-ov-file#hybrid-mode-configuration-requires-vuelanguage-server-version-200
      ts-ls.enable = true;
      #eslint.enable = true;
      volar = {
        enable = true;
        package = pkgs.vue-language-server;
        tslsIntegration = true;
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
}
