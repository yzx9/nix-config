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
    ];
    text = ''
      # Proxy configuration
      ${lib.optionalString hasProxy "export HTTPS_PROXY=http://${config.proxy.httpProxy}"}

      # Inject API keys at runtime
      with-secrets "${config.age.secrets."llm-api-keys".path}" \
        --map GLM_CODING_API_KEY ANTHROPIC_AUTH_TOKEN \
        -- claude "$@"
    '';
  };
in
{
  age.secrets."llm-api-keys".file = ../secrets/llm-api-keys.age;

  programs.claude-code = {
    enable = config.purpose.dev.enable;
    package = claude-code';

    # See: https://code.claude.com/docs/en/settings
    settings = {
      env = {
        # Custom API endpoint for GLM
        ANTHROPIC_BASE_URL = "https://api.z.ai/api/anthropic";
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
          "Bash(git commit:*)"
          "Bash(git diff:*)"
          "Bash(git status:*)"
        ];

        # Permissions that require confirmation
        ask = [
          "Bash(git add:*)"
          "Bash(git reset:*)"
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
          "Bash(git push:*)"
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
          # Stop: when Claude is ready for more input
          # Notification: when Claude requests permissions or noop for 60s
          Notification = [
            {
              matcher = "*";
              hooks = [
                {
                  type = "command";
                  command = mkNotifyCmd "Claude Code is ready for more action!";
                }
              ];
            }
          ];
        };
    };

    # see also: https://github.com/VoltAgent/awesome-claude-code-subagents
    agents =
      let
        awesome-subagents = pkgs.fetchFromGitHub {
          owner = "VoltAgent";
          repo = "awesome-claude-code-subagents";
          rev = "8c67a2f9c85335a204828e01e5399f357892b6a9";
          hash = "sha256-iI7b9Sh/wj2qIeCe/E5PrWvgld6XSUllujeE8Lbs6vs=";
        };
      in
      {
        debugger = "${awesome-subagents}/categories/04-quality-security/debugger.md";
        python-pro = "${awesome-subagents}/categories/02-language-specialists/python-pro.md";
        rust-engineer = "${awesome-subagents}/categories/02-language-specialists/rust-engineer.md";
        vue-expert = "${awesome-subagents}/categories/02-language-specialists/vue-expert.md";
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
        allowed-tools: Bash(git add:*), Bash(git diff:*), Bash(git status:*), Bash(git commit:*)
        description: Create a git commit with proper message
        ---

        ## Context

        - Current git status: !`git status`
        - Current git diff: !`git diff HEAD`
        - Recent commits: !`git log --oneline -5`

        ## Task

        Based on the changes above, run the necessary check steps, including formatting and testing
        if applicable. Then stage the changes and create a concise, descriptive git commit message.
      '';
    };
  };

  home.file.".claude/plugins/.lsp.json".text = toJSON {
    go = {
      command = lib.getExe pkgs.gopls;
      args = [ "serve" ];
      extensionToLanguage.".go" = "go";
    };

    rust = {
      command = lib.getExe pkgs.rust-analyzer;
      args = [ ];
      extensionToLanguage.".rs" = "rust";
    };

    typescript = {
      command = lib.getExe pkgs.typescript-language-server;
      args = [ "--stdio" ];
      extensionToLanguage.".ts" = "typescript";
    };
  };
}
