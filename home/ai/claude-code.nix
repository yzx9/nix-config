{
  config,
  pkgs,
  lib,
  ...
}:

let
  hasProxy = config.proxy.httpPublicProxy != null;

  skills = import ./skills.nix { inherit pkgs; };

  # Claude Code wrapper script to inject API keys at runtime
  claude-code' = pkgs.writeShellApplication {
    name = "claude";

    runtimeInputs = [
      pkgs.yzx9.with-secrets
      pkgs.claude-code
    ];

    runtimeEnv = {
      HTTPS_PROXY = lib.optionalString hasProxy "http://${config.proxy.httpPublicProxy}";
    };

    text = ''
      PROVIDER="''${PROVIDER:-glm}"

      case "$PROVIDER" in
        glm)
          API_KEY_NAME="GLM_CODING_API_KEY"
          export ANTHROPIC_BASE_URL="https://open.bigmodel.cn/api/anthropic"
          export ANTHROPIC_DEFAULT_OPUS_MODEL="glm-5.1"
          export ANTHROPIC_DEFAULT_SONNET_MODEL="glm-5.1"
          export ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.7"
          ;;
        uni)
          API_KEY_NAME="UNI_YUANJING_API_KEY"
          export ANTHROPIC_BASE_URL="https://maas-api.ai-yuanjing.com/openapi/compatible-mode"
          export ANTHROPIC_DEFAULT_OPUS_MODEL="glm-5"
          export ANTHROPIC_DEFAULT_SONNET_MODEL="glm-5"
          export ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-5"
          ;;
        *)
          echo "Unknown PROVIDER: $PROVIDER"
          exit 1
          ;;
      esac

      with-secrets "${config.age.secrets."llm-api-keys".path}" \
        --map "$API_KEY_NAME" ANTHROPIC_AUTH_TOKEN \
        --allow CONTEXT7_API_KEY \
        --allow GITHUB_PAT \
        --allow GLM_CODING_API_KEY \
        --allow ZOTERO_API_KEY \
        --allow ZOTERO_LIBRARY_ID \
        -- claude "$@"
    '';
  };
in
{
  programs.claude-code = {
    enable = config.purpose.dev.enable;
    package = claude-code';
    inherit skills;

    # See: https://code.claude.com/docs/en/settings
    settings = {
      env = {
        # Custom API endpoint
        API_TIMEOUT_MS = "3000000";

        # Disable non-essential traffic for privacy
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = 1;

        # Experimental feature
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      };

      theme = "dark";
      editorMode = "vim";
      effortLevel = "high"; # "low", "medium", "high"

      permissions = {
        # Default permission mode
        defaultMode = "acceptEdits";

        # Deny > Ask > Allow
        deny = [
          "Read(./.env)"
          "Read(./.env.*)"
          "Read(./secrets/**)"
        ];

        ask = [
          "Bash(git reset *)"
          "Bash(git force *)"
          "Bash(git push *)"
          "Bash(gh pr close *)"
          "Bash(gh pr create *)"
          "Bash(gh issue close *)"
          "Bash(gh issue delete *)"
          "Bash(rm -rf *)"
          "Bash(cargo add *)"
        ];

        allow = [
          "Read(**/*)" # allow reading all files, but deny specific sensitive files below
          "Read(~/.cargo/registry/*)"
          "Read(/nix/store/*)"

          "Search"
          "WebFetch" # allow any fetches
          "WebSearch" # allow any searches

          "Bash(curl *)"

          "Bash(git add *)"
          "Bash(git commit *)"
          "Bash(git diff *)"
          "Bash(git status *)"

          "Bash(cargo build *)"
          "Bash(cargo check *)"
          "Bash(cargo clippy *)"
          "Bash(cargo fmt *)"
          "Bash(cargo test *)"

          "Bash(nix build *)"
          "Bash(nix eval *)"
          "Bash(nix hash *)"
          "Bash(nix-build *)"
          "Bash(nix-instantiate *)"
          "Bash(nix-prefetch-url:*)"

          "mcp__plugin_claude-code-home-manager_context7"
          "mcp__plugin_claude-code-home-manager_github__get_*"
          "mcp__plugin_claude-code-home-manager_github__list_*"
          "mcp__plugin_claude-code-home-manager_github__search_*"
          "mcp__plugin_claude-code-home-manager_github__issue_read"
          "mcp__plugin_claude-code-home-manager_playwright"
          "mcp__plugin_claude-code-home-manager_zai-vision"
          "mcp__plugin_claude-code-home-manager_zai-web-reader"
          "mcp__plugin_claude-code-home-manager_zai-web-search"
          "mcp__plugin_claude-code-home-manager_zai-zread"
          "mcp__plugin_claude-code-home-manager_zotero-mcp__zotero_get_*"
          "mcp__plugin_claude-code-home-manager_zotero-mcp__zotero_search_*"
          "mcp__plugin_claude-code-home-manager_zotero-mcp__zotero_list_*"
          "mcp__plugin_claude-code-home-manager_zotero-mcp__zotero_switch_library"
        ];

        # Additional working directories Claude can access
        additionalDirectories = [
          "~/.matplotlib/" # for python plotting
          "~/.cache/" # for various language toolchains
          "~/.gstack/" # gstack runtime state (sessions, projects, etc.)
          "/nix/store" # nix store for reading installed packages and tools
        ];
      };

      sandbox = {
        enabled = true;
        autoAllowBashIfSandboxed = true;
        excludedCommands = [
          "codex"
          "docker"
          "nix"
        ];

        filesystem = {
          allowRead = [
            "/nix/store/"
          ];
          allowWrite = [
            "~/.gstack/"
          ];
        };

        network = {
          allowedDomains = [
            "github.com"
            "*.npmjs.org"
            "registry.yarnpkg.com"
            "*.crates.io"
          ];
          allowUnixSockets = [
            "/var/run/docker.sock"
            "/nix/var/nix/daemon-socket/socket"
          ];
          allowLocalBinding = true;
        };
      };

      attribution = {
        # To hide all attribution, set commit and pr to empty strings.
        commit = "";
        pr = "";
      };

      hooks =
        let
          direnvHook = {
            type = "command";
            command = "direnv export bash >> \"$CLAUDE_ENV_FILE\"";
          };

          mkNotifyCmd =
            msg:
            if pkgs.stdenvNoCC.hostPlatform.isDarwin then
              "${pkgs.terminal-notifier}/bin/terminal-notifier -title 'Claude Code' -message '${msg}' -activate 'net.kovidgoyal.kitty'"
            else
              "${lib.getBin pkgs.libnotify}/notify-send 'Claude Code' '${msg}'";
        in
        {
          CwdChanged = [ { hooks = [ direnvHook ]; } ];

          FileChanged = [
            {
              matcher = ".envrc|.env|flake.nix|flake.lock";
              hooks = [ direnvHook ];
            }
          ];

          # Stop: when Claude is ready for more input
          # Notification: when Claude requests permissions or noop for 60s
          Notification = lib.optionals config.purpose.gui [
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

    context = ''
      ## General Guidelines
      - You are living in a nix-managed environment with declarative configuration.
        Don't install packages imperatively.
        Instead, try to use `nix-env` or `npx` to add packages and tools to the environment
      - Use `github` MCP for any GitHub-related interactions, such as searching and exploring repositorie.
        Prefer `github` MCP over `zai-zread` for GitHub interactions
      - Use `context7` MCP tools whenever you need to search documentation
      - Use `playwright` MCP for any web automation tasks, such as testing web apps
    '';

    lspServers = {
      go = {
        command = "gopls";
        args = [ "serve" ];
        extensionToLanguage.".go" = "go";
      };

      pyright = {
        command = "pyright-langserver";
        args = [ "--stdio" ];
        extensionToLanguage = {
          ".py" = "python";
          ".pyi" = "python";
        };
      };

      rust-analyzer = {
        command = "rust-analyzer";
        extensionToLanguage.".rs" = "rust";
      };

      typescript = {
        command = "typescript-language-server";
        args = [ "--stdio" ];
        extensionToLanguage = {
          ".ts" = "typescript";
          ".tsx" = "typescriptreact";
          ".js" = "javascript";
          ".jsx" = "javascriptreact";
          ".mts" = "typescript";
          ".cts" = "typescript";
          ".mjs" = "javascript";
          ".cjs" = "javascript";
        };
      };

      vue = {
        command = "vue-language-server";
        args = [ "--stdio" ];
        extensionToLanguage.".vue" = "vue";
      };
    };

    mcpServers = {
      github = {
        type = "http";
        url = "https://api.githubcopilot.com/mcp/";
        headers.Authorization = "Bearer \${GITHUB_PAT}";
      };

      context7 = {
        type = "http";
        url = "https://mcp.context7.com/mcp";
        headers.CONTEXT7_API_KEY = "\${CONTEXT7_API_KEY}";
      };

      playwright = {
        type = "stdio";
        command = lib.getExe pkgs.playwright-mcp;
      };

      zai-vision = {
        type = "stdio";
        command = lib.getExe pkgs.yzx9.zai-mcp-server;
        env = {
          Z_AI_API_KEY = "\${GLM_CODING_API_KEY}";
          Z_AI_MODE = "ZHIPU";
        };
      };

      zai-web-search = {
        type = "http";
        url = "https://open.bigmodel.cn/api/mcp/web_search_prime/mcp";
        headers.Authorization = "Bearer \${GLM_CODING_API_KEY}";
      };

      zai-web-reader = {
        type = "http";
        url = "https://open.bigmodel.cn/api/mcp/web_reader/mcp";
        headers.Authorization = "Bearer \${GLM_CODING_API_KEY}";
      };

      zotero-mcp = {
        type = "stdio";
        command = lib.getExe pkgs.yzx9.zotero-mcp;
        args = [ "serve" ];
        env = {
          ZOTERO_LOCAL = "true";
          ZOTERO_API_KEY = "\${ZOTERO_API_KEY}";
          ZOTERO_LIBRARY_ID = "\${ZOTERO_LIBRARY_ID}";
        };
      };

      zai-zread = {
        type = "http";
        url = "https://open.bigmodel.cn/api/mcp/zread/mcp";
        headers.Authorization = "Bearer \${GLM_CODING_API_KEY}";
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
        debugger = ./agents/debugger.md;
        python-pro = read "02-language-specialists/python-pro.md";
        rust-engineer = read "02-language-specialists/rust-engineer.md";
        frontend-developer = read "01-core-development/frontend-developer.md";
        code-reviewer = read "04-quality-security/code-reviewer.md";
      };
  };

  # Create symlinks for gstack skills
  home.activation.gstack-skills = lib.mkIf config.purpose.dev.enable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      GSTACK="${pkgs.yzx9.gstack}/share/gstack"

      # Main gstack directory (skills reference ~/.claude/skills/gstack/bin/ etc.)
      ln -sfn "$GSTACK" "$HOME/.claude/skills/gstack"

      # Individual skill symlinks (Claude Code discovers skills here)
      for dir in "$GSTACK"/*/; do
        skill="''${dir%/}"
        skill="''${skill##*/}"
        [ -f "$dir/SKILL.md" ] || continue
        [ "$skill" = "node_modules" ] && continue
        ln -sfn "gstack/$skill" "$HOME/.claude/skills/$skill"
      done

      # Runtime state directory
      mkdir -p "$HOME/.gstack/projects" "$HOME/.gstack/sessions"
    ''
  );

  # NOTE: gstack config is not fully YAML-compliant, dont use toYAML
  home.file.".gstack/config.yaml".text = ''
    auto_upgrade: false
    update_check: false
    telemetry: off

    skill_prefix: false
    routing_declined: true

    codex_reviews: enabled
    proactive: true
    cross_project_learnings: true
  '';
}
