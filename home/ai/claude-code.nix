{
  config,
  pkgs,
  lib,
  ...
}:

let
  hasProxy = config.proxy.httpPublic != null;

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
          export ANTHROPIC_DEFAULT_OPUS_MODEL="glm-5.2"
          export ANTHROPIC_DEFAULT_SONNET_MODEL="glm-5.2"
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
        --allow GITHUB_PERSONAL_ACCESS_TOKEN \
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

    # See: https://code.claude.com/docs/en/settings
    settings = {
      env = {
        # Custom API endpoint
        API_TIMEOUT_MS = "3000000";
        ## Enable tool search for all tools
        #ENABLE_TOOL_SEARCH = "yes";
        # Disable non-essential traffic for privacy
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = 1;
        # # Disable 1M token context for 3rd party models
        # CLAUDE_CODE_DISABLE_1M_CONTEXT = 1;
      };

      theme = "dark";
      editorMode = "vim";
      effortLevel = "high"; # "low", "medium", "high"
      tui = "fullscreen";

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
          deny = [ ];

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
          ++ (mkBashCmds [
            "curl"
            "rg"
            "mvn"
          ])
          ++ (mkBashSubCmds "git" [
            "add"
            "commit"
            "diff"
            "fetch"
            "log"
            "pull"
            "rebase"
            "stash"
            "status"
          ])
          ++ (mkBashSubCmds "gh" [
            "run"
            "workflow"
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
            "list_branches"
            "list_commits"
            "list_issues"
            "list_pull_requests"
            "list_releases"
            "list_tags"
            "get_commit"
            "get_file_contents"
            "get_latest_release"
            "get_me"
            "get_tag"
            "search_code"
            "search_commits"
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
            "~/.cache/" # various language toolchains
            "~/.m2/" # maven dependencies
            "~/.matplotlib/" # python plotting
            "~/.npm/" # npm packages and cache
            "/nix/store" # nix store for reading installed packages and toolsclaude
          ];
        };

      sandbox = {
        enabled = true;
        autoAllowBashIfSandboxed = true;
        excludedCommands = [
          "codex"
          "docker"
          "gh"
          "nix"
        ];

        filesystem.allowRead = [
          "/nix/store/"
        ];

        network = {
          allowedDomains = [
            "registry.yarnpkg.com"
            "raw.githubusercontent.com"
            "files.pythonhosted.org"
            "*.crates.io"
            "*.github.com"
            "*.npmjs.org"
            "*.pypi.org"
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
          # https://github.com/direnv/direnv/wiki/Claude-Code
          direnvHook = pkgs.writeScript "direnv-hook" ''
            #!/bin/bash
            # Writes direnv setup to CLAUDE_ENV_FILE, which is sourced before each Bash command.
            # Also wraps cd so mid-command directory changes re-evaluate direnv.

            if [ -n "$CLAUDE_ENV_FILE" ]; then
              cat >> "$CLAUDE_ENV_FILE" <<'DIRENV'
            eval "$(direnv export bash)"
            cd() {
              builtin cd "$@" && eval "$(direnv export bash)"
            }
            DIRENV
            fi
            exit 0
          '';

          direnvHookDef = {
            type = "command";
            command = direnvHook;
          };

          mkNotifyCmd =
            msg:
            if pkgs.stdenvNoCC.hostPlatform.isDarwin then
              "${pkgs.terminal-notifier}/bin/terminal-notifier -title 'Claude Code' -message '${msg}' -activate 'net.kovidgoyal.kitty'"
            else
              "${lib.getBin pkgs.libnotify}/notify-send 'Claude Code' '${msg}'";
        in
        {
          SessionStart = [ { hooks = [ direnvHookDef ]; } ];

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

      skills = import ./skills.nix { inherit pkgs; };

      skillOverrides =
        let
          toKV = value: skills: lib.listToAttrs (lib.map (name: { inherit name value; }) skills);
          mkNameOnly = toKV "name-only";
          mkUserInvocableOnly = toKV "user-invocable-only";
          mkOff = toKV "off";
        in
        mkNameOnly [
          # gstack
          "browse"
          "codex"
          "cso"
          "design-consultation"
          "design-html"
          "design-review"
          "design-shotgun"
          "devex-review"
          "gstack"
          "investigate"
          "land-and-deploy"
          "landing-report"
          "office-hours"
          "plan-ceo-review"
          "plan-design-review"
          "plan-devex-review"
          "plan-eng-review"
          "plan-tune"
          "qa"
          "qa-only"
          "review"
          "ship"
          "spec"
        ]
        // mkUserInvocableOnly [
          # gstack
          "autoplan"
          "context-restore"
          "context-save"
          "document-generate"
          "document-release"
          "retro"
          "make-pdf"
        ]
        // mkOff [
          # gstack - sprint
          "pair-agent"
          # gstack - power tools
          "careful"
          "canary"
          "freeze"
          "unfreeze"
          "gstack-upgrade"
          "guard"
          "setup-browser-cookies"
          "setup-deploy"
          "setup-gbrain"
          "sync-gbrain"
          "ios-clean"
          "ios-design-review"
          "ios-fix"
          "ios-qa"
          "ios-sync"
          # gstack - misc
          "benchmark-models"
          "connect-chrome"
          "health"
          "open-gstack-browser"
          "scrape"
          "skillify"
        ];
    };

    context = ''
      ## General Guidelines

      - You are living in a nix-managed environment with declarative configuration. Don't install packages imperatively.
        Instead, use tools such as `nix-env` or `npx` to make packages and utilities available in the environment
      - Additional tools may be available through tool search. Search for the relevant tool when you need to use GitHub,
        fetch library/documentation context with Context7, automate or inspect web pages with Playwright, perform visual
        checks with zai-vision, search the web with zai-web-search, or read web pages with zai-web-reader. Do not assume
        exact tool names
      - Some tools may be available through tool search, including GitHub, Context7, Playwright, vision, web search, and
        web reader tools. Search when needed; do not assume exact tool names
      - For read-only GitHub-related tasks, use the `github` MCP, such as repository search and code exploration. When
        the GitHub MCP is insufficient, use the `gh` CLI
      - For web automation tasks, use the `playwright` MCP, especially when testing web applications
      - For documentation lookups, try the `context7` MCP first
      - Perform visual checks with `zai-vision`
      - Search the web with `zai-web-search`; read web pages with `zai-web-reader`

      ## Understanding tool_reference Response Type

      When ToolSearch returns a response containing:
      {"type": "tool_reference", "tool_name": "Workflow"}

      This means the tool is now available. Call it directly:
      Workflow({script: "...", title: "..."})
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
        type = "stdio";
        command = lib.getExe pkgs.github-mcp-server;
        args = [
          "stdio"
          "--read-only"
        ];
        env.GITHUB_PERSONAL_ACCESS_TOKEN = "\${GITHUB_PERSONAL_ACCESS_TOKEN}";
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
          rev = "945f491f0f453dfd735262d4d98825a5227ac301";
          hash = "sha256-XBSYxi2qZMbmTOKLTnSmmvSMyrnGzT4WiSeUOcVyYEU=";
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
