{
  config,
  pkgs,
  lib,
  ...
}:

let
  hasProxy = config.my.proxy.httpPublic != null;

  # Opencode wrapper script to inject API keys at runtime
  opencode' = pkgs.writeShellApplication {
    name = "opencode";
    runtimeInputs = [
      pkgs.yzx9.with-secrets
      pkgs.opencode
    ];

    runtimeEnv = {
      # Disable automatic LSP download for privacy
      OPENCODE_DISABLE_LSP_DOWNLOAD = "true";
    }
    # Proxy configuration
    // (lib.optionalAttrs hasProxy {
      HTTPS_PROXY = config.my.proxy.httpPublic;
    });

    # Inject API keys at runtime
    text = ''
      with-secrets "${config.age.secrets."llm-api-keys".path}" \
        --allow GLM_CODING_API_KEY \
        --allow UNI_YUANJING_API_KEY \
        -- opencode "$@"
    '';
  };

  skills = import ./skills.nix { inherit pkgs; };
in
{
  programs.opencode = {
    enable = config.my.host.dev.enable;
    package = opencode';
    inherit skills;

    settings = {
      theme = "system";

      provider = {
        zhipuai-coding-plan.options.apiKey = "{env:GLM_CODING_API_KEY}";

        uni = {
          npm = "@ai-sdk/openai-compatible";
          name = "UNI Yuanjing";
          options = {
            baseURL = "https://maas-api.ai-yuanjing.com/openapi/compatible-mode/v1";
            apiKey = "{env:UNI_YUANJING_API_KEY}";
          };
          models.glm-5 = {
            name = "GLM-5";
            limit = {
              context = 204800;
              output = 131072;
            };
          };
        };
      };

      permission = {
        read = {
          ".envrc" = "deny";
          "./.env" = "deny";
          "./.env.*" = "deny";
          "./secrets/**" = "deny";
        };

        bash = {
          "rm *" = "ask";
          "git add *" = "ask";
          "git reset *" = "ask";
          "git force *" = "ask";
          "git push *" = "deny";
          "gh pr create *" = "ask";
          "gh pr close *" = "ask";
          "gh issue close *" = "ask";
          "gh issue delete *" = "ask";

          # rust
          "cargo build *" = "allow";
          "cargo check *" = "allow";
          "cargo fmt *" = "allow";
          "cargo test *" = "allow";
        };
      };

      mcp = { };
    };

    context = ''
      ## General
    '';
  };

  # Send notification on session completion
  xdg.configFile."opencode/plugins/notification.js".text =
    lib.optionalString config.my.host.dev.enable
      (
        let
          msg = "Turn Completed!";
          notifyCmd =
            if pkgs.stdenvNoCC.hostPlatform.isDarwin then
              "${pkgs.terminal-notifier}/bin/terminal-notifier -title 'opencode' -message '${msg}' -activate 'net.kovidgoyal.kitty'"
            else
              "${lib.getBin pkgs.libnotify}/notify-send 'opencode' '${msg}'";
        in
        ''
          export const NotificationPlugin = async ({ project, client, $, directory, worktree }) => ({
            async event({ event }) {
              if (event.type === "session.idle") {
                await $`${notifyCmd}`;
              }
            }
          })
        ''
      );
}
