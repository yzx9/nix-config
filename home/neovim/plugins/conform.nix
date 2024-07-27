# Lightweight yet powerful formatter plugin for Neovim
# homepage: https://github.com/stevearc/conform.nvim
# nixvim doc: https://nix-community.github.io/nixvim/plugins/conform-nvim/index.html
{ ... }:

{
  programs.nixvim.plugins.conform-nvim = {
    enable = true;
    formatOnSave = {
      lspFallback = true;
      timeoutMs = 500;
    };
    notifyOnError = true;
    formattersByFt = {
      html = [
        [
          "prettierd"
          "prettier"
        ]
      ];
      css = [
        [
          "prettierd"
          "prettier"
        ]
      ];
      javascript = [
        [
          "prettierd"
          "prettier"
        ]
      ];
      typescript = [
        [
          "prettierd"
          "prettier"
        ]
      ];
      vue = [
        [
          "prettierd"
          "prettier"
        ]
      ];
      markdown = [
        [
          "prettierd"
          "prettier"
        ]
      ];
      python = [
        "isort"
        "black"
      ];
      rust = [ "rustfmt" ];
      nix = [ "nixfmt" ];
      go = [
        "goimports"
        "gofmt"
      ];
      yaml = [
        "yamllint"
        "yamlfmt"
      ];
    };
  };
}
