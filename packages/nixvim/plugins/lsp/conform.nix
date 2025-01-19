# Lightweight yet powerful formatter plugin for Neovim
# homepage: https://github.com/stevearc/conform.nvim
# nixvim doc: https://nix-community.github.io/nixvim/plugins/conform-nvim/index.html
{ pkgs, lib, ... }:

{
  plugins.conform-nvim = {
    enable = true;
    settings = {
      notify_on_error = true;
      formatters_by_ft =
        let
          genPrettier =
            langs:
            lib.genAttrs langs (lang: {
              __unkeyed-1 = "prettierd";
              __unkeyed-2 = "prettier";
              stop_after_first = true;
            });
        in
        genPrettier [
          "html"
          "css"
          "javascript"
          "typescript"
          "vue"
          "markdown"
        ]
        // {
          python = [
            # To fix auto-fixable lint errors.
            "ruff_fix"
            # To run the Ruff formatter.
            "ruff_format"
            # To organize the imports.
            "ruff_organize_imports"
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
          sh = [ "shfmt" ];
        };

      formatters = {
        prettierd.command = lib.getExe pkgs.prettierd;
        ruff_fix.command = lib.getExe pkgs.ruff;
        ruff_format.command = lib.getExe pkgs.ruff;
        ruff_organize_imports.command = lib.getExe pkgs.ruff;
        # rustfmt.command = lib.getExe pkgs.rustfmt;
        # goimports.command = "${pkgs.gotools}/bin/goimports";
        # gofmt.command = lib.getExe pkgs.go;
        nixfmt.command = lib.getExe pkgs.nixfmt-rfc-style;
        yamlfmt.command = lib.getExe pkgs.yamlfmt;
        yamllint.command = lib.getExe pkgs.yamllint;
        shfmt.command = lib.getExe pkgs.shfmt;
      };

      format_on_save = ''
        function(bufnr)
          -- Disable with a global or buffer-local variable
          if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
            return
          end
          return { timeout_ms = 500, lsp_format = "fallback" }
        end
      '';
    };
  };

  extraConfigLua = ''
    vim.api.nvim_create_user_command("FormatDisable", function(args)
      if args.bang then
        -- FormatDisable! will disable formatting just for this buffer
        vim.b.disable_autoformat = true
      else
        vim.g.disable_autoformat = true
      end
    end, {
      desc = "Disable autoformat-on-save",
      bang = true,
    })
    vim.api.nvim_create_user_command("FormatEnable", function()
      vim.b.disable_autoformat = false
      vim.g.disable_autoformat = false
    end, {
      desc = "Re-enable autoformat-on-save",
    })
  '';
}
