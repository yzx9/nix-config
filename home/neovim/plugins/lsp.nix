# nixvim doc: https://nix-community.github.io/nixvim/plugins/lsp/index.html
{ ... }:

{
  programs.nixvim.plugins.lsp = {
    enable = true;

    keymaps = {
      diagnostic = {
        "<leader>j" = "goto_next";
        "<leader>k" = "goto_prev";
      };

      lspBuf = {
        "<leader>la" = {
          action = "code_action";
          desc = "LSP code action";
        };
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
        K = {
          action = "hover";
          desc = "LSP hover";
        };
      };
    };

    servers = {
      dockerls.enable = true;
      docker-compose-language-service.enable = true;
      gopls.enable = true;
      lua-ls.enable = true;
      nginx-language-server.enable = true;
      nixd.enable = true;
      pyright.enable = true;
      html.enable = true;
      cssls.enable = true;
      tsserver.enable = true;
      eslint.enable = true;
      volar.enable = true;
      jsonls.enable = true;
      yamlls.enable = true;

      typos-lsp = {
        enable = true;
        extraOptions.init_options.diagnosticSeverity = "Hint";
      };
    };
  };
}
