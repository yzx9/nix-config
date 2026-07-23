{
  config,
  pkgs,
  lib,
  ...
}:

let
  hasProxy = config.my.proxy.httpPublic != null;
  enableSearch = false;

  # age-managed secret file. `.envrc`-style lines: `KEY=value` or
  # `export KEY=value`.
  secretFile = config.age.secrets."llm-api-keys".path;

  # Prints a single API key from the trusted age secret file to stdout, for use
  # as Claude Code's `apiKeyHelper`. Routing auth through `apiKeyHelper` (a
  # settings-level credential) rather than an `ANTHROPIC_AUTH_TOKEN` shell var
  # means the token no longer depends on env inheritance, which background /
  # AgentView sessions drop since v2.1.174. Errors go to stderr; a missing file
  # or empty key exits non-zero. Only the trusted age file is parsed, never an
  # arbitrary project `.envrc`.
  mkApiKeyHelper =
    name: key:
    pkgs.writeShellApplication {
      inherit name;
      text = ''
        # NB: on Darwin agenix sets `.path` to `$(getconf DARWIN_USER_TEMP_DIR)/…`,
        # so this must stay double-quoted for the command substitution to expand.
        file="${secretFile}"
        key="${key}"

        if [[ ! -r "$file" ]]; then
          echo "${name}: cannot read secret file: $file" >&2
          exit 1
        fi

        value=""
        while IFS= read -r line || [ -n "$line" ]; do
          case "$line" in
            "" | \#*) continue ;;
            export\ *) line="''${line#export }" ;;
          esac
          case "$line" in
            "$key="*) value="''${line#"$key="}" ;;
          esac
        done < "$file"

        if [[ -z "$value" ]]; then
          echo "${name}: key '$key' not found or empty in: $file" >&2
          exit 1
        fi

        printf '%s' "$value"
      '';
    };

  # Per-provider profiles. The base URL, model aliases (and the proxy, when set)
  # are written into a generated settings JSON passed via `claude --settings`,
  # so they are read by every session type — including background workers, which
  # no longer inherit these from the dispatch shell. The API key itself is never
  # written to disk; it is resolved at call time via `apiKeyHelper`.
  providers = {
    glm = {
      key = "GLM_CODING_API_KEY";
      settings = {
        env = {
          ANTHROPIC_BASE_URL = "https://open.bigmodel.cn/api/anthropic";
          ANTHROPIC_DEFAULT_OPUS_MODEL = "glm-5.2[1m]";
          ANTHROPIC_DEFAULT_SONNET_MODEL = "glm-5.2[1m]";
          ANTHROPIC_DEFAULT_HAIKU_MODEL = "glm-4.7";
        };

        attribution.commit = "Assisted-by: Claude-Code:GLM-5.2";
      };
    };
    uni = {
      key = "UNI_YUANJING_API_KEY";
      settings = {
        env = {
          ANTHROPIC_BASE_URL = "https://maas-api.ai-yuanjing.com/openapi/compatible-mode";
          ANTHROPIC_DEFAULT_OPUS_MODEL = "glm-5.2";
          ANTHROPIC_DEFAULT_SONNET_MODEL = "glm-5";
          ANTHROPIC_DEFAULT_HAIKU_MODEL = "glm-5";
          # Disable 1M token context for 3rd party models
          CLAUDE_CODE_DISABLE_1M_CONTEXT = "1";
        };

        attribution.commit = "Assisted-by: Claude-Code:GLM-5";
      };
    };
  };

  # One generated `settings.json` per provider: the profile `env` plus the
  # matching `apiKeyHelper`. Deep-merged with the HM-managed user settings, so
  # permissions/sandbox/hooks/etc. are preserved.
  providerSettings = lib.mapAttrs (
    name: p:
    pkgs.writeText "claude-code-${name}-settings.json" (
      builtins.toJSON (
        p.settings // { apiKeyHelper = lib.getExe (mkApiKeyHelper "claude-${name}-api-key-helper" p.key); }
      )
    )
  ) providers;

  # Claude Code wrapper. `$PROVIDER` (default `glm`) selects the profile, then
  # the upstream binary runs with the matching generated settings file.
  # `with-secrets` now only exposes non-Anthropic secrets (MCP tokens) to the
  # process; the Anthropic auth token comes from `apiKeyHelper`. The upstream
  # binary is invoked by absolute path to avoid recursing into this wrapper, and
  # any extra args from the caller (historically `--plugin-dir` from the HM
  # module) are carried through untouched via `"$@"`.
  claude-code' = pkgs.writeShellApplication {
    name = "claude";
    passthru.version = pkgs.claude-code.version;

    runtimeInputs = [ pkgs.yzx9.with-secrets ];

    runtimeEnv = lib.optionalAttrs hasProxy { HTTPS_PROXY = config.my.proxy.httpPublic; };

    text = ''
      PROVIDER="''${PROVIDER:-glm}"

      case "$PROVIDER" in
        glm)
          settings="${providerSettings.glm}" ;;
        uni)
          settings="${providerSettings.uni}" ;;
        *)
          echo "claude: unknown PROVIDER: $PROVIDER (expected glm|uni)" >&2
          exit 1 ;;
      esac

      with-secrets "${secretFile}" \
        --allow CONTEXT7_API_KEY \
        --allow GITHUB_PERSONAL_ACCESS_TOKEN \
        --allow GLM_CODING_API_KEY \
        --allow TAVILY_API_KEY \
        --allow ZOTERO_API_KEY \
        --allow ZOTERO_LIBRARY_ID \
        -- "${lib.getExe pkgs.claude-code}" "$@" --settings "$settings"
    '';
  };
in
{
  programs.claude-code = {
    enable = config.my.host.dev.enable;
    package = claude-code';

    # See: https://code.claude.com/docs/en/settings
    settings = {
      env = {
        ## Enable tool search for all tools
        ENABLE_TOOL_SEARCH = if enableSearch then "yes" else "false";
        # Custom API endpoint
        API_TIMEOUT_MS = "3000000";
        # Disable non-essential traffic for privacy
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = 1;
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
          defaultMode = "auto";

          # Deny > Ask > Allow
          deny = [ ];

          ask =
            mkBashCmds [
              "rm -rf"
            ]
            ++ (mkBashSubCmds "git" [
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
            "Agent(isolation:worktree)"

            "Search"
            "WebFetch" # allow any fetches
            "WebSearch" # allow any searches
          ]
          ++ (mkBashCmds [
            "curl"
            "rg"
            "mvn"
            "nix-instantiate"
            "nix-prefetch-url"
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
          ++ (mkHmMcps [
            "context7"
            "playwright"
            "tavily"
            "zai-vision"
            "zai-web-reader"
            "zai-web-search"
            # "zai-zread"
          ])
          ++ (mkHmMcpCmds "github" [
            "get_*"
            "list_*"
            "search_*"
            "issue_read"
            "pull_request_read"
          ])
          ++ (mkHmMcpCmds "zotero-mcp" [
            "get_*"
            "list_*"
            "search_*"
            "create_note"
            "semantic_search"
            "switch_library"
          ]);

          # Additional working directories Claude can access
          # additionalDirectories = [ ];
        };

      sandbox = {
        enabled = true;
        autoAllowBashIfSandboxed = true;
        failIfUnavailable = true;

        excludedCommands = [
          "codex *"
          "docker *"
          "gh *"
          "mvn *"
          "nix *"
          "cargo build *"
          "cargo check *"
          "cargo clippy *"
          "cargo test *"
        ];

        sandbox.filesystem.disabled = true; # disable due to E2BIG: #73437 #73468 #74032 #74081

        # Default read behavior: read access to the entire computer
        filesystem.allowWrite = [
          "~/.cache/"
          "~/.cargo" # rust dependencies and cache
          "~/.gradle" # gradle dependencies and cache
          "~/.m2/" # maven dependencies
          "~/.matplotlib/" # python plotting
          "~/.npm/" # npm packages and cache
          "~/.local/share/direnv" # direnv config
          "~/.local/state/pnpm" # pnpm state
          "~/go/pkg" # go dependencies and cache
        ]
        ++ lib.optionals pkgs.stdenvNoCC.hostPlatform.isLinux [
          "~/.local/share/pnpm" # pnpm store
        ]
        ++ lib.optionals pkgs.stdenvNoCC.hostPlatform.isDarwin [
          "~/Library/Caches"
          "~/Library/pnpm" # pnpm v11 global store location, otherwise pnpm falls back to <project>/.pnpm-store
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

            # codex
            "api.openai.com"
            "chatgpt.com"
          ];
          allowUnixSockets = [
            "/var/run/docker.sock"
            "/nix/var/nix/daemon-socket/socket"
          ];
          allowLocalBinding = true;
        }
        // (lib.optionalAttrs hasProxy {
          httpProxyPort = config.my.proxy.httpPublicPort;
        });
      };

      # To hide attribution, set to empty strings.
      attribution.pr = "";

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
          Notification = lib.optionals config.my.host.gui [
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

          # mattpocock/skills: /grill-me launches /grilling by name, so keep
          # grilling's name visible to the model but hide its description (no
          # trigger context → it won't auto-fire). NOT user-invocable-only —
          # that hides grilling entirely and breaks grill-me's call to it.
          "grilling"
        ]
        // mkUserInvocableOnly [
          # gstack
          "autoplan"
          "context-restore"
          "context-save"
          "diagram"
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

    skills = import ./skills.nix { inherit pkgs; };

    context = ''
      ## General Guidelines
      - You are living in a nix-managed environment with declarative configuration. Don't install packages imperatively.
        Instead, use tools such as `nix-env` or `npx` to make packages and utilities available in the environment
      - The user often use voice input, which may occasionally lead to transcription errors. If a word or phrase doesn’t
        seem to make sense, please first consider possible phonetic alternatives.
      - Stop before pushing, even in the background session. Don’t draft a PR.

      ## Tool Usage
      - For read-only GitHub-related tasks, use the `github` MCP, such as repository search and code exploration. When
        the GitHub MCP is insufficient, use the `gh` CLI
      - For web automation tasks, use the `playwright` MCP, especially when testing web applications
      - For documentation lookups, try the `context7` MCP first
      - Perform visual checks with `zai-vision`
      - Search the web with `tavily`
    ''
    + lib.optionalString enableSearch ''
      - Some tools may be available through tool search, including GitHub, Context7, Playwright, vision and web search
        tools. Search when needed; do not assume exact tool names

      ### Understanding tool_reference Response Type
      When ToolSearch returns a response containing: {"type": "tool_reference", "tool_name": "Workflow"}
      This means the tool is now available. Call it directly: Workflow({script: "...", title: "..."})
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

      tavily = {
        type = "stdio";
        command = lib.getExe pkgs.yzx9.tavily-mcp;
        env = {
          TAVILY_API_KEY = "\${TAVILY_API_KEY}";
          # axios 1.16 mishandles HTTP proxies for HTTPS targets (plain HTTP -> 443).
          # Tavily is reachable directly, so bypass the local proxy.
          NO_PROXY = "\${NO_PROXY},api.tavily.com";
          no_proxy = "\${no_proxy},api.tavily.com";
        };
      };

      zai-vision = {
        type = "stdio";
        command = lib.getExe pkgs.yzx9.zai-mcp-server;
        env = {
          Z_AI_API_KEY = "\${GLM_CODING_API_KEY}";
          Z_AI_MODE = "ZHIPU";
        };
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
    };

    # See also: https://github.com/VoltAgent/awesome-claude-code-subagents
    agents =
      let
        awesome-subagents = pkgs.fetchFromGitHub {
          owner = "VoltAgent";
          repo = "awesome-claude-code-subagents";
          rev = "977dfeaaf3d2252a8ace0c68438d08d39965ed43";
          hash = "sha256-kRDbIuai2m5aFU+U2ZpbZyt7kAAkKMlJhTHEGMzwfaE=";
        };

        # PERF: remove readFile
        read = fname: lib.readFile "${awesome-subagents}/categories/${fname}";
      in
      {
        frontend-developer = read "01-core-development/frontend-developer.md";
        backend-developer = read "01-core-development/backend-developer.md";
        code-reviewer = read "04-quality-security/code-reviewer.md";
      };
  };
}
