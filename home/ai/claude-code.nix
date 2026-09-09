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

  # Prints a single API key from the trusted age secret file to stdout; see
  # ./api-key-helper.nix for the full rationale.
  mkApiKeyHelper =
    name: key:
    import ./api-key-helper.nix {
      inherit pkgs name key;
      file = secretFile;
    };

  # Per-provider profiles; see ./claude-code-providers.nix for the data.
  providers = import ./claude-code-providers.nix;

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

    runtimeInputs = [
      pkgs.yzx9.with-secrets
    ];

    runtimeEnv = lib.optionalAttrs hasProxy {
      HTTPS_PROXY = config.my.proxy.httpPublic;
    };

    text = ''
      PROVIDER="''${PROVIDER:-glm}"

      case "$PROVIDER" in
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (provider: settings: ''
            ${lib.escapeShellArg provider})
              settings=${lib.escapeShellArg (toString settings)}
              ;;
          '') providerSettings
        )}
        *)
          echo "claude: unknown PROVIDER: $PROVIDER (expected glm|uni)" >&2
          exit 1 ;;
      esac

      with-secrets "${secretFile}" \
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
      disableDeepLinkRegistration = "disable"; # claude-cli:// and Claude Code URL Handler.app

      permissions =
        let
          mkBashCmds = lib.map (cmd: "Bash(${cmd} *)");
          mkBashSubCmds = cmd: lib.map (subcmd: "Bash(${cmd} ${subcmd} *)");
          mkHmMcps = lib.map (mcp: "mcp__plugin_hm_${mcp}");
          mkHmMcpCmds = mcp: lib.map (cmd: "mcp__plugin_hm_${mcp}__${cmd}");
        in
        {
          # Default permission mode
          defaultMode = "auto";

          # Deny > Ask > Allow
          deny = mkHmMcpCmds "tavily" [ "tavily_research" ]; # Too expensive

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

            "EnterWorktree"
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
            "tavily"
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
          allowAllUnixSockets = true;
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
            # Writes direnv setup to CLAUDE_ENV_FILE, which is sourced before each Bash command.
            # Also wraps cd so mid-command directory changes re-evaluate direnv.

            if [ -n "$CLAUDE_ENV_FILE" ]; then
              cat >> "$CLAUDE_ENV_FILE" <<'DIRENV'
            __claude_direnv_export() {
              local output
              local stderr_file
              local exit_code
              local shell

              stderr_file="$(mktemp)"

              if [ -n "''${ZSH_VERSION:-}" ]; then
                shell=zsh
              else
                shell=bash
              fi

              output="$(direnv export "$shell" 2>"$stderr_file")"
              exit_code=$?

              if [ "$exit_code" -ne 0 ]; then
                cat "$stderr_file" >&2
                rm -f "$stderr_file"
                return "$exit_code"
              fi

              rm -f "$stderr_file"
              eval "$output"
            }

            __claude_direnv_export
            cd() {
              builtin cd "$@" && __claude_direnv_export
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
          "codex"
          "gstack"
          "office-hours"
          "plan-ceo-review"
          "plan-design-review"
          "plan-devex-review"
          "plan-eng-review"
          "plan-tune"
          "review"

          # mattpocock/skills: /grill-me launches /grilling by name, so keep
          # grilling's name visible to the model but hide its description (no
          # trigger context → it won't auto-fire). NOT user-invocable-only —
          # that hides grilling entirely and breaks grill-me's call to it.
          "grilling"
        ]
        // mkUserInvocableOnly [
          # gstack
          "autoplan"
          "browse"
          "context-restore"
          "context-save"
          "cso"
          "design-consultation"
          "design-html"
          "design-review"
          "design-shotgun"
          "devex-review"
          "diagram"
          "document-generate"
          "document-release"
          "investigate"
          "land-and-deploy"
          "landing-report"
          "qa"
          "qa-only"
          "retro"
          "ship"
          "spec"
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
      ## General
      - You are living in a nix-managed environment with declarative configuration. Don't install packages imperatively. Instead, use `nix-shell` to use packages and utilities
      - The user often use voice input, which may occasionally lead to transcription errors. If a word or phrase doesn’t seem to make sense, please first consider possible phonetic alternatives
      - Don't push or open PRs without asking — even in background sessions; publishing stays under my manual control

      ## Tool Usage
      - For GitHub-related tasks, use the `gh` CLI
      - Search the web with `tavily`
    ''
    + lib.optionalString enableSearch ''
      - Some tools may be available through tool search, including GitHub, vision and web search tools. Search when needed; do not assume exact tool names

      ### Understanding tool_reference Response Type
      When ToolSearch returns a response containing: {"type": "tool_reference", "tool_name": "Workflow"}. This means the tool is now available. Call it directly: Workflow({script: "...", title: "..."})
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
    };
  };
}
