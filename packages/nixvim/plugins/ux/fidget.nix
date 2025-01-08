# Extensible UI for Neovim notifications and LSP progress messages.
# homepage: https://github.com/j-hui/fidget.nvim
# nixvim doc: https://nix-community.github.io/nixvim/plugins/fidget/index.html
{ lib, ... }:

{
  plugins.fidget = {
    enable = true;

    settings = {
      logger = {
        level = "warn"; # “off”, “error”, “warn”, “info”, “debug”, “trace”

        # Limit the number of decimals displayed for floats
        float_precision = 1.0e-2;
      };

      progress = {
        # How and when to poll for progress messages
        poll_rate = 0;

        # Suppress new messages while in insert mode
        suppress_on_insert = true;

        # Ignore new tasks that are already complete
        ignore_done_already = false;

        # Ignore new tasks that don't contain a message
        ignore_empty_message = false;

        # Clear notification group when LSP server detaches
        clear_on_detach = lib.nixvim.mkRaw ''
          function(client_id)
            local client = vim.lsp.get_client_by_id(client_id)
            return client and client.name or nil
          end
        '';

        # How to get a progress message's notification group key
        notification_group = lib.nixvim.mkRaw ''
          function(msg) return msg.lsp_client.name end
        '';

        # List of LSP servers to ignore
        ignore = [ ];

        lsp = {
          # Configure the nvim's LSP progress ring buffer size
          progress_ringbuf_size = 0;
        };

        display = {
          # How many LSP messages to show at once
          render_limit = 16;

          # How long a message should persist after completion
          done_ttl = 3;

          # Icon shown when all LSP progress tasks are complete
          done_icon = "✔";

          # Highlight group for completed LSP tasks
          done_style = "Constant";

          # How long a message should persist when in progress
          progress_ttl = lib.nixvim.mkRaw "math.huge";

          # Icon shown when LSP progress tasks are in progress
          progress_icon = {
            pattern = "dots";
            period = 1;
          };

          # Highlight group for in-progress LSP tasks
          progress_style = "WarningMsg";

          # Highlight group for group name (LSP server name)
          group_style = "Title";

          # Highlight group for group icons
          icon_style = "Question";

          # Ordering priority for LSP notification group
          priority = 30;

          # Whether progress notifications should be omitted from history
          skip_history = true;

          # How to format a progress message
          format_message = lib.nixvim.mkRaw ''
            require ("fidget.progress.display").default_format_message
          '';

          # How to format a progress annotation
          format_annote = lib.nixvim.mkRaw ''
            function (msg) return msg.title end
          '';

          # How to format a progress notification group's name
          format_group_name = lib.nixvim.mkRaw ''
            function (group) return tostring (group) end
          '';

          # Override options from the default notification config
          overrides = {
            rust_analyzer = {
              name = "rust-analyzer";
            };
          };
        };
      };

      notification = {
        # How frequently to update and render notifications
        poll_rate = 10;

        # “off”, “error”, “warn”, “info”, “debug”, “trace”
        filter = "info";

        # Number of removed messages to retain in history
        history_size = 128;

        override_vim_notify = true;

        redirect = lib.nixvim.mkRaw ''
          function(msg, level, opts)
            if opts and opts.on_open then
              return require("fidget.integration.nvim-notify").delegate(msg, level, opts)
            end
          end
        '';

        configs.default = lib.nixvim.mkRaw ''
          require('fidget.notification').default_config
        '';

        window = {
          normal_hl = "Comment";
          winblend = 0;
          border = "none"; # none, single, double, rounded, solid, shadow
          zindex = 45;
          max_width = 0;
          max_height = 0;
          x_padding = 1;
          y_padding = 0;
          align = "bottom";
          relative = "editor";
        };

        view = {
          # Display notification items from bottom to top
          stack_upwards = true;

          # Separator between group name and icon
          icon_separator = " ";

          # Separator between notification groups
          group_separator = "---";

          # Highlight group used for group separator
          group_separator_hl = "Comment";
        };
      };
    };
  };
}
