{
  config,
  pkgs,
  lib,
  ...
}:

let
  # hasProxy = config.proxy.httpPublicProxy != null;
  hasProxy = false;
  toJSON = lib.generators.toJSON { };

  # Claude Code wrapper script to inject API keys at runtime
  claude-code' = pkgs.writeShellApplication {
    name = "claude";

    runtimeInputs = [
      pkgs.yzx9.with-secrets
      pkgs.claude-code
    ];

    runtimeEnv = {
      # Proxy configuration
      HTTPS_PROXY = lib.optionalString hasProxy "http://${config.proxy.httpProxy}";
    };

    # Inject API keys at runtime
    text = ''
      with-secrets "${config.age.secrets."llm-api-keys".path}" \
        --map GLM_CODING_API_KEY ANTHROPIC_AUTH_TOKEN \
        -- claude "$@"
    '';
  };

  skills = import ./skills.nix { inherit pkgs; };
in
{
  programs.claude-code = {
    enable = config.purpose.dev.enable;
    package = claude-code';
    inherit skills;

    # See: https://code.claude.com/docs/en/settings
    settings = {
      env = {
        # Custom API endpoint for GLM
        # ANTHROPIC_BASE_URL = "https://api.z.ai/api/anthropic";
        ANTHROPIC_BASE_URL = "https://open.bigmodel.cn/api/anthropic";
        API_TIMEOUT_MS = "3000000";

        # Disable non-essential traffic for privacy
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = 1;

        ANTHROPIC_DEFAULT_OPUS_MODEL = "GLM-5";
        ANTHROPIC_DEFAULT_SONNET_MODEL = "GLM-4.7";
        ANTHROPIC_DEFAULT_HAIKU_MODEL = "GLM-4.7";

        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      };

      theme = "dark";

      permissions = {
        # Default permission mode
        defaultMode = "acceptEdits";

        # Allowed permissions
        allow = [
          "Read(**/*)" # allow reading all files, but deny specific sensitive files below
          "WebFetch" # allow any fetches
          "WebSearch" # allow any searches
          "Bash(git commit:*)"
          "Bash(git diff:*)"
          "Bash(git status:*)"
          "Bash(cargo build:*)"
          "Bash(cargo check:*)"
          "Bash(cargo clippy:*)"
          "Bash(cargo fmt:*)"
          "Bash(cargo test:*)"
          "Bash(nix build:*)"
          "Bash(nix eval:*)"
          "Bash(nix-build:*)"
          "Bash(nix-instantiate:*)"
        ];

        # Permissions that require confirmation
        ask = [
          "Bash(git add:*)"
          "Bash(git reset:*)"
          "Bash(git force:*)"
          "Bash(git push:*)"
          "Bash(gh pr close:*)"
          "Bash(gh pr create:*)"
          "Bash(gh issue close:*)"
          "Bash(gh issue delete:*)"
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
        additionalDirectories = [
          "~/.matplotlib" # for python plotting
          "~/.cache/" # for various language toolchains
        ];
      };

      sandbox = {
        enabled = true;
        autoAllowBashIfSandboxed = true;
        # excludedCommands = [ "docker" ];
        network = {
          #   allowUnixSockets = [ "/var/run/docker.sock" ];
          allowLocalBinding = true;
        };
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

        # PERF: remove readFile
        read = fname: lib.readFile "${awesome-subagents}/categories/${fname}";
      in
      {
        debugger = read "04-quality-security/debugger.md";
        python-pro = read "02-language-specialists/python-pro.md";
        rust-engineer = read "02-language-specialists/rust-engineer.md";
        frontend-developer = read "01-core-development/frontend-developer.md";
        code-reviewer = read "04-quality-security/code-reviewer.md";
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
