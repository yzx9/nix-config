# Lightweight yet powerful formatter plugin for Neovim
# homepage: https://github.com/stevearc/conform.nvim
# nixvim doc: https://nix-community.github.io/nixvim/plugins/conform-nvim/index.html
{
  config,
  pkgs,
  lib,
  ...
}:

lib.mkIf config.lsp.enable {
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
          "css"
          "html"
          "javascript"
          "json"
          "markdown"
          "typescript"
          "vue"
        ]
        // {
          go = [
            "goimports"
            "gofmt"
          ];
          nix = [ "nixfmt" ];
          python = [
            "ruff_fix" # To fix auto-fixable lint errors.
            "ruff_format" # To run the Ruff formatter.
            "ruff_organize_imports" # To organize the imports.
          ];
          rust = [ "rustfmt" ];
          sh = [ "shfmt" ];
          toml = [ "taplo" ];
          yaml = [
            "prettierd"
            "prettier"
            "yamllint"
          ];
        };

      formatters = {
        # goimports.command = lib.getExe' pkgs.gotools "goimports""};
        # gofmt.command = lib.getExe pkgs.go;
        ruff_fix.command = lib.getExe pkgs.ruff;
        ruff_format.command = lib.getExe pkgs.ruff;
        ruff_organize_imports.command = lib.getExe pkgs.ruff;
        # rustfmt.command = lib.getExe pkgs.rustfmt;
        shfmt.command = lib.getExe pkgs.shfmt;
        toml.command = lib.getExe pkgs.taplo;
        prettierd.command = lib.getExe pkgs.prettierd;
        nixfmt.command = lib.getExe pkgs.nixfmt-rfc-style;
        yamllint.command = lib.getExe pkgs.yamllint;
      };

      format_on_save = ''
        function(bufnr)
          -- Disable with a global or buffer-local variable
          if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
            return
          end
          -- Disable autoformat for files in a certain path
          local bufname = vim.api.nvim_buf_get_name(bufnr)
          if bufname:match("/node_modules/") then
            return
          end
          return { timeout_ms = 500, lsp_format = "fallback" }
        end
      '';
    };

    lazyLoad.settings = {
      cmd = "ConformInfo";
      event = "BufWritePre";
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
