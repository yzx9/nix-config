{
  config,
  pkgs,
  lib,
  ...
}:

{
  # See: https://code.claude.com/docs/en/settings
  programs.claude-code = {
    settings = {
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

          mkCommandHook = command: {
            type = "command";
            inherit command;
          };

          mkNotifyCmd =
            msg:
            if pkgs.stdenvNoCC.hostPlatform.isDarwin then
              "${pkgs.terminal-notifier}/bin/terminal-notifier -title 'Claude Code' -message '${msg}' -activate 'net.kovidgoyal.kitty'"
            else
              "${lib.getBin pkgs.libnotify}/notify-send 'Claude Code' '${msg}'";
        in
        {
          SessionStart = [ { hooks = [ (mkCommandHook direnvHook) ]; } ];

          # Stop: when Claude is ready for more input
          # Notification: when Claude requests permissions or noop for 60s
          Notification = lib.optionals config.my.host.gui [
            {
              matcher = "*";
              hooks = [ (mkCommandHook (mkNotifyCmd "Claude Code is ready for more action!")) ];
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

      skills = import ../skills.nix { inherit pkgs; };
    };

    lspServers = {
      go = {
        command = lib.getExe pkgs.gopls;
        args = [ "serve" ];
        extensionToLanguage.".go" = "go";
      };

      pyright = {
        command = lib.getExe pkgs.pyright;
        args = [ "--stdio" ];
        extensionToLanguage = lib.genAttrs [ ".py" ".pyi" ] (_: "python");
      };

      rust-analyzer = {
        command = "rust-analyzer";
        extensionToLanguage.".rs" = "rust";
      };

      typescript = {
        command = lib.getExe pkgs.typescript-language-server;
        args = [ "--stdio" ];
        extensionToLanguage =
          lib.genAttrs [ ".js" ".mjs" ".cjs" ] (_: "javascript")
          // lib.genAttrs [ ".ts" ".tsx" ".mts" ".cts" ] (_: "typescript")
          // {
            ".tsx" = "typescriptreact";
            ".jsx" = "javascriptreact";
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
        }
        # axios 1.16 mishandles HTTP proxies for HTTPS targets (plain HTTP -> 443).
        # Tavily is reachable directly, so bypass the local proxy.
        // lib.genAttrs [ "NO_PROXY" "no_proxy" ] (name: "\${name} = \"\${\${name}},api.tavily.com\";");
      };
    };
  };
}
