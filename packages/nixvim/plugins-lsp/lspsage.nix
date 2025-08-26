# improve neovim lsp experience
# homepage: https://github.com/nvimdev/lspsaga.nvim
# nixvim doc: https://nix-community.github.io/nixvim/plugins/lspsaga/index.html
{
  config,
  lib,
  icons,
  ...
}:

lib.mkIf config.lsp.enable {
  plugins.lspsaga = {
    enable = true;

    settings = {
      beacon.enable = true;

      code_action = {
        show_server_name = true;
        only_in_cursor = true;
        keys = {
          exec = "<CR>";
          quit = [
            "<Esc>"
            "q"
          ];
        };
      };

      ui = {
        border = "rounded"; # One of none, single, double, rounded, solid, shadow
        code_action = "${icons.DiagnosticHint}"; # Can be any symbol you want 💡
      };

      finder.keys.quit = [
        "<Esc>"
        "q"
      ];

      hover = {
        open_cmd = "!firefox"; # Choose your browser
      };

      implement.enable = false;

      lightbulb = {
        enable = true;
        sign = true;
        virtual_text = false;
      };

      outline.close_after_jump = true;

      rename = {
        auto_save = false;
        in_select = false;
        keys = {
          exec = "<CR>";
          quit = [
            "<C-k>"
            "<Esc>"
          ];
          select = "x";
        };
      };

      # Breadcrumbs
      symbol_in_winbar.enable = true;

      scroll_preview = {
        scroll_down = "<C-f>";
        scroll_up = "<C-b>";
      };

      # lazyLoad.settings.cmd = "Lspsaga";
    };
  };

  # Enable catppuccin colors
  # https://github.com/catppuccin/nvim/blob/main/lua/catppuccin/groups/integrations/lsp_saga.lua
  colorschemes.catppuccin.settings.integrations.lsp_saga = true;

  keymaps = [
    {
      mode = "n";
      key = "gd";
      action = "<cmd>Lspsaga finder def<CR>";
      options = {
        desc = "Goto Definition";
        silent = true;
      };
    }

    {
      mode = "n";
      key = "gD";
      action = "<cmd>Lspsaga show_line_diagnostics<CR>";
      options = {
        desc = "Goto Declaration";
        silent = true;
      };
    }

    {
      mode = "n";
      key = "gr";
      action = "<cmd>Lspsaga finder ref<CR>";
      options = {
        desc = "Goto References";
        silent = true;
      };
    }

    {
      mode = "n";
      key = "gi";
      action = "<cmd>Lspsaga finder imp<CR>";
      options = {
        desc = "Goto Implementation";
        silent = true;
      };
    }

    {
      mode = "n";
      key = "gt";
      action = "<cmd>Lspsaga peek_type_definition<CR>";
      options = {
        desc = "Type Definition";
        silent = true;
      };
    }

    {
      mode = "n";
      key = "K";
      action = "<cmd>Lspsaga hover_doc<CR>";
      options = {
        desc = "Hover";
        silent = true;
      };
    }

    {
      mode = "n";
      key = "<leader>lo";
      action = "<cmd>Lspsaga outline<CR>";
      options = {
        desc = "Outline";
        silent = true;
      };
    }

    {
      mode = "n";
      key = "<leader>lr";
      action = "<cmd>Lspsaga rename<CR>";
      options = {
        desc = "Rename";
        silent = true;
      };
    }

    {
      mode = "n";
      key = "<leader>la";
      action = "<cmd>Lspsaga code_action<CR>";
      options = {
        desc = "Code Action";
        silent = true;
      };
    }

    {
      mode = "n";
      key = "<leader>ld";
      action = "<cmd>Lspsaga show_line_diagnostics<CR>";
      options = {
        desc = "Line Diagnostics";
        silent = true;
      };
    }

    {
      mode = "n";
      key = "[d";
      action = "<cmd>Lspsaga diagnostic_jump_next<CR>";
      options = {
        desc = "Next Diagnostic";
        silent = true;
      };
    }

    {
      mode = "n";
      key = "]d";
      action = "<cmd>Lspsaga diagnostic_jump_prev<CR>";
      options = {
        desc = "Previous Diagnostic";
        silent = true;
      };
    }
  ];
}
