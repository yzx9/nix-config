{
  config,
  pkgs,
  lib,
  ...
}:

let
  hasProxy = config.proxy.httpPublicProxy != null;
  toJSON = lib.generators.toJSON { };

  # Claude Code wrapper script to inject API keys at runtime
  claude-code' = pkgs.writeShellApplication {
    name = "claude";
    runtimeInputs = [
      pkgs.yzx9.with-secrets
      pkgs.claude-code

      # TODO: configure LSP
      # pkgs.pyright
      # pkgs.typescript-language-server
      # pkgs.rust-analyzer
    ];
    text = ''
      # Proxy configuration
      ${lib.optionalString hasProxy "export HTTPS_PROXY=http://${config.proxy.httpPublicProxy}"}

      # Inject API keys at runtime
      with-secrets "${config.age.secrets."llm-api-keys".path}" \
        --map GLM_CODING_API_KEY ANTHROPIC_AUTH_TOKEN \
        -- claude "$@"
    '';
  };
in
{
  # has been added in ./goose.nix
  # age.secrets."llm-api-keys".file = ../secrets/llm-api-keys.age;

  programs.claude-code = {
    enable = config.purpose.dev.enable;
    package = claude-code';

    # See: https://code.claude.com/docs/en/settings
    settings = {
      env = {
        # Custom API endpoint for GLM
        ANTHROPIC_BASE_URL = "https://open.bigmodel.cn/api/anthropic";
        API_TIMEOUT_MS = "3000000";

        # Disable non-essential traffic for privacy
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = 1;
      };

      theme = "dark";

      permissions = {
        # Default permission mode
        defaultMode = "acceptEdits";

        # Allowed permissions
        allow = [
          "Read(**/*)"
          "Bash(git status:*)"
          "Bash(git diff:*)"
        ];

        # Permissions that require confirmation
        ask = [
          "Bash(git push:*)"
          "Bash(git force:*)"
          "Bash(rm:*)"
          "Bash(curl:*)"
          "Bash(cargo add:*)"
        ];

        # Denied permissions
        deny = [
          "Read(.envrc)"
          "Read(./.env)"
          "Read(./.env.*)"
          "Read(./secrets/**)"
        ];

        # Additional working directories Claude can access
        additionalDirectories = [ ];
      };

      sandbox = {
        enabled = true;
        autoAllowBashIfSandboxed = true;
        # excludedCommands = [ "docker" ];
        # network = {
        #   allowUnixSockets = [ "/var/run/docker.sock" ];
        #   allowLocalBinding = true;
        # };
      };

      attribution = {
        # To hide all attribution, set commit and pr to empty strings.
        commit = "";
        pr = "";
      };

      # MCP server configuration
      enableAllProjectMcpServers = false;
      enabledMcpjsonServers = [
        "memory"
        "github"
      ];
      disabledMcpjsonServers = [ "filesystem" ];

      hooks =
        let
          mkNotifyCmd =
            msg:
            if pkgs.stdenvNoCC.hostPlatform.isDarwin then
              "osascript -e 'display notification \"${msg}\" with title \"Claude Code\"'"
            else
              "${lib.getBin pkgs.libnotify}/notify-send 'Claude Code' '${msg}'";
        in
        lib.mkIf config.purpose.gui {
          Stop = [
            {
              matcher = "";
              hooks = [
                {
                  type = "command";
                  command = mkNotifyCmd "Claude Code is ready for more action!";
                }
              ];
            }
          ];

          Notification = [
            {
              matcher = "";
              hooks = [
                {
                  type = "command";
                  command = mkNotifyCmd "Claude Code needs help!";
                }
              ];
            }
          ];
        };
    };

    commands = {
      changelog = ''
        ---
        allowed-tools: Bash(git log:*), Bash(git diff:*)
        argument-hint: [version] [change-type] [message]
        description: Update CHANGELOG.md with new entry
        ---
        Parse the version, change type, and message from the input
        and update the CHANGELOG.md file accordingly.
      '';

      commit = ''
        ---
        allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)
        description: Create a git commit with proper message
        ---
        ## Context

        - Current git status: !`git status`
        - Current git diff: !`git diff HEAD`
        - Recent commits: !`git log --oneline -5`

        ## Task

        Based on the changes above, create a single atomic git commit with a descriptive message.
      '';
    };
  };

  home.file.".claude/plugins/.lsp.json".text = toJSON {
    go = {
      command = lib.getExe pkgs.gopls;
      args = [ "serve" ];
      extensionToLanguage = {
        ".go" = "go";
      };
    };

    rust = {
      command = lib.getExe pkgs.rust-analyzer;
      args = [ ];
      extensionToLanguage = {
        ".rs" = "rust";
      };
    };

    typescript = {
      command = lib.getExe pkgs.typescript-language-server;
      args = [ "--stdio" ];
    };
  };
}
