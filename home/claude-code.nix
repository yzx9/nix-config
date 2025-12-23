{
  config,
  pkgs,
  lib,
  ...
}:

let
  hasProxy = config.proxy.httpPublicProxy != null;

  # Claude Code wrapper script to inject API keys at runtime
  claude-code' = pkgs.writeShellApplication {
    name = "claude";
    runtimeInputs = [
      pkgs.with-secrets
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
        ANTHROPIC_DEFAULT_HAIKU_MODEL = "GLM-4.7";

        # Disable non-essential traffic for privacy
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = 1;
      };

      theme = "dark";

      permissions = {
        # Default permission mode
        defaultMode = "acceptEdits";

        # Allowed permissions
        allow = [ ];

        # Denied permissions
        deny = [
          "Read(.envrc)"
          "Read(./.env)"
          "Read(./.env.*)"
          "Read(./secrets/**)"
        ];

        # Permissions that require confirmation
        ask = [
          "Bash(git push:*)"
          "Bash(git force:*)"
          "Bash(rm:*)"
          "Bash(curl:*)"
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
    };
  };
}
