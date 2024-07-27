# nixvim doc: https://nix-community.github.io/nixvim/plugins/lsp/index.html
{ pkgs, lib, ... }:

{
  programs.nixvim.plugins.lsp = {
    enable = true;

    keymaps = {
      diagnostic = {
        "<leader>j" = "goto_next";
        "<leader>k" = "goto_prev";
      };

      lspBuf = {
        # following line was replaced by lspsaga
        # "<leader>la" = {
        #   action = "code_action";
        #   desc = "LSP code action";
        # };
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
        # K = {
        #   action = "hover";
        #   desc = "LSP hover";
        # };
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

      typos-lsp = {
        enable = true;
        extraOptions.init_options.diagnosticSeverity = "Hint";
      };
    };
  };
}
