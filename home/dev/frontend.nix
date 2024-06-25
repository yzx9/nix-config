{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nodejs
    corepack
    nodePackages.prettier
    vscode-langservers-extracted

    # typescript
    typescript
    nodePackages.typescript-language-server
    biome

    # vue
    nodePackages.volar

    # tailwindcss
    tailwindcss-language-server
  ];

  programs.helix.languages = {
    language = [
      {
        name = "javascript";
        auto-format = true;
        language-servers = [
          {
            name = "typescript-language-server";
            except-features = [ "format" ];
          }
          "biome"
        ];
      }
      {
        name = "typescript";
        auto-format = true;
        language-servers = [
          {
            name = "typescript-language-server";
            except-features = [ "format" ];
          }
          "biome"
        ];
      }
      {
        name = "json";
        auto-format = true;
        language-servers = [
          {
            name = "vscode-json-language-server";
            except-features = [ "format" ];
          }
          "biome"
        ];
      }
      {
        name = "vue";
        auto-format = true;
        formatter = {
          command = "prettier";
          args = [
            "--parser"
            "vue"
          ];
        };
      }
    ];
    language-server = {
      typescript = {
        command = "typescript-language-server";
        language-server.config.plugins = {
          name = "@vue/typescript-plugin";
          location = "${pkgs.nodePackages.volar}/bin/vue-language-server";
          languages = [ "vue" ];
        };
      };
      biome = {
        command = "biome";
        args = [ "lsp-proxy" ];
      };
    };
  };
}
