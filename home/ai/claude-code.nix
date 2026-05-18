{
  config,
  pkgs,
  lib,
  ...
}:

let
  hasProxy = config.proxy.httpPublic != null;

  skills = import ./skills.nix { inherit pkgs; };

  # Claude Code wrapper script to inject API keys at runtime
  claude-code' = pkgs.writeShellApplication {
    name = "claude";

    runtimeInputs = [
      pkgs.yzx9.with-secrets
      pkgs.claude-code
    ];

    runtimeEnv = lib.optionalAttrs hasProxy {
      HTTPS_PROXY = config.proxy.httpPublic;
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
        # Disable 1M token context for 3rd party models
        CLAUDE_CODE_DISABLE_1M_CONTEXT = 1;
        # Enable experimental agent teams feature
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      };

      theme = "dark";
      editorMode = "vim";
      effortLevel = "high"; # "low", "medium", "high"

      permissions =
        let
          mkBashCmds = lib.map (cmd: "Bash(${cmd} *)");
          mkBashSubCmds = cmd: lib.map (subcmd: "Bash(${cmd} ${subcmd} *)");
          mkHmMcps = lib.map (mcp: "mcp__plugin_claude-code-home-manager_${mcp}");
          mkHmMcpCmds = mcp: lib.map (cmd: "mcp__plugin_claude-code-home-manager_${mcp}__${cmd}");
        in
        {
          # Default permission mode
          defaultMode = "acceptEdits";

          # Deny > Ask > Allow
          deny = [
            "Read(./.env)"
            "Read(./.env.*)"
            "Read(./secrets/**)"
          ];

          ask =
            mkBashCmds [
              "rm -rf"
              "cargo add"
            ]
            ++ (mkBashSubCmds "git" [
              "force"
              "reset"
              "push"
            ])
            ++ (mkBashSubCmds "gh" [ "run" ])
            ++ (mkBashSubCmds "gh pr" [
              "close"
              "create"
            ])
            ++ (mkBashSubCmds "gh issue" [
              "close"
              "delete"
            ]);

          allow = [
            "Read(**/*)" # allow reading all files, but deny specific sensitive files below
            "Read(~/.cargo/registry/*)"
            "Read(/nix/store/*)"

            "Search"
            "WebFetch" # allow any fetches
            "WebSearch" # allow any searches
          ]
          ++ (mkBashCmds [ "curl" ])
          ++ (mkBashSubCmds "git" [
            "add"
            "commit"
            "diff"
            "fetch"
            "pull"
            "rebase"
            "stash"
            "status"
          ])
          ++ (mkBashSubCmds "cargo" [
            "build"
            "check"
            "clippy"
            "fmt"
            "test"
          ])
          ++ (mkBashSubCmds "nix" [
            "build"
            "eval"
            "hash"
            "log"
            "why-depends"
          ])
          ++ (mkBashCmds [
            "nix-instantiate"
            "nix-prefetch-url"
          ])
          ++ (mkHmMcps [
            "context7"
            "playwright"
            "zai-vision"
            "zai-web-reader"
            "zai-web-search"
            # "zai-zread"
          ])
          ++ (mkHmMcpCmds "github" [
            "issue_read"
            "pull_request_read"
            "list_commits"
            "list_issues"
            "list_releases"
            "list_tags"
            "get_file_contents"
            "get_latest_release"
            "get_tag"
            "search_code"
            "search_repositories"
            "search_issues"
            "search_pull_requests"
          ])
          ++ (mkHmMcpCmds "zotero-mcp" [
            "create_note"
            "get_item_metadata"
            "get_item_fulltext"
            "get_item_children"
            "list_libraries"
            "semantic_search"
            "get_notes"
            "search_items"
            "switch_library"
          ]);

          # Additional working directories Claude can access
          additionalDirectories = [
            "~/.matplotlib/" # for python plotting
            "~/.cache/" # for various language toolchains
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

        filesystem.allowRead = [
          "/nix/store/"
        ];

        network = {
          allowedDomains = [
            "github.com"
            "registry.yarnpkg.com"
            "*.npmjs.org"
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

      skillOverrides =
        let
          toKV = value: skills: lib.listToAttrs (lib.map (name: { inherit name value; }) skills);
          mkNameOnly = toKV "name-only";
        in
        mkNameOnly [
          # gstack
          "autoplan"
          "benchmark-models"
          "browse"
          "canary"
          "careful"
          "codex"
          "context-restore"
          "context-save"
          "cso"
          "design-consultation"
          "design-html"
          "design-review"
          "design-shotgun"
          "devex-review"
          "document-release"
          "find-skills"
          "freeze"
          "gstack"
          "gstack-upgrade"
          "guard"
          "health"
          "investigate"
          "land-and-deploy"
          "landing-report"
          "make-pdf"
          "office-hours"
          "connect-chrome"
          "open-gstack-browser"
          "pair-agent"
          "plan-ceo-review"
          "plan-design-review"
          "plan-devex-review"
          "plan-eng-review"
          "plan-tune"
          "qa"
          "qa-only"
          "retro"
          "review"
          "scrape"
          "setup-browser-cookies"
          "setup-deploy"
          "setup-gbrain"
          "ship"
          "skill-creator"
          "skillify"
          "sync-gbrain"
          "unfreeze"
        ];
    };

    context = ''
      ## General Guidelines
      - You are living in a nix-managed environment with declarative configuration. Don't install packages imperatively.
        Instead, use tools such as `nix-env` or `npx` to make packages and utilities available in the environment
      - Use `rg` instead of `find -exec` when searching files
      - Use `github` MCP for GitHub-related interactions, such as searching and exploring repositorie
      - Use `context7` MCP whenever you need to search documentation
      - Use `playwright` MCP for any web automation tasks, such as testing web apps
    '';

    lspServers = {
      go = {
        command = lib.getExe pkgs.gopls;
        args = [ "serve" ];
        extensionToLanguage.".go" = "go";
      };

      pyright = {
        command = lib.getExe pkgs.pyright;
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
        command = lib.getExe pkgs.typescript-language-server;
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
        command = lib.getExe pkgs.vue-language-server;
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
        args = [
          "--headless"
          "--isolated"
        ];
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

      # zotero-mcp = lib.mkIf (!pkgs.stdenv.hostPlatform.isAarch64) {
      #   type = "stdio";
      #   command = lib.getExe pkgs.yzx9.zotero-mcp;
      #   args = [ "serve" ];
      #   env = {
      #     ZOTERO_LOCAL = "true";
      #     ZOTERO_API_KEY = "\${ZOTERO_API_KEY}";
      #     ZOTERO_LIBRARY_ID = "\${ZOTERO_LIBRARY_ID}";
      #   };
      # };

      # zai-zread = {
      #   type = "http";
      #   url = "https://open.bigmodel.cn/api/mcp/zread/mcp";
      #   headers.Authorization = "Bearer \${GLM_CODING_API_KEY}";
      # };
    };

    # See also: https://github.com/VoltAgent/awesome-claude-code-subagents
    agents =
      let
        awesome-subagents = pkgs.fetchFromGitHub {
          owner = "VoltAgent";
          repo = "awesome-claude-code-subagents";
          rev = "6f804f0cfab22fb62668855aa3d62ee3a1453077";
          hash = "sha256-ObuKw41RqwfZrLo8uxPVDJXmAwyMMRr9v2O1yyMNI7Q=";
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
}
