{
  config,
  pkgs,
  lib,
  ...
}:

let
  # hasProxy = config.proxy.httpPublicProxy != null;

  # Opencode wrapper script to inject API keys at runtime
  opencode' = pkgs.writeShellApplication {
    name = "opencode";
    runtimeInputs = [
      pkgs.yzx9.with-secrets
      pkgs.opencode
    ];

    runtimeEnv = {
      # Proxy configuration
      # HTTPS_PROXY = lib.optionalString hasProxy "http://${config.proxy.httpProxy}";

      # Disable automatic LSP download for privacy
      OPENCODE_DISABLE_LSP_DOWNLOAD = "true";
    };

    # Inject API keys at runtime
    text = ''
      with-secrets "${config.age.secrets."llm-api-keys".path}" \
        --allow GLM_CODING_API_KEY \
        -- opencode "$@"
    '';
  };

  skills = import ./skills.nix { inherit pkgs; };
in
{
  programs.opencode = {
    enable = config.purpose.dev.enable;
    package = opencode';
    inherit skills;

    settings = {
      theme = "system";

      provider.zhipuai.options = {
        baseURL = "https://open.bigmodel.cn/api/coding/paas/v4";
        apiKey = "{env:GLM_CODING_API_KEY}";
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
    };
  };

  xdg.configFile."opencode/plugins/notification.js".text =
    let
      msg = "Session Completed!";
      notifyCmd =
        if pkgs.stdenvNoCC.hostPlatform.isDarwin then
          "osascript -e 'display notification \"${msg}\" with title \"opencode\"'"
        else
          "${lib.getBin pkgs.libnotify}/notify-send 'opencode' '${msg}'";
    in
    ''
      export const NotificationPlugin = async ({ project, client, $, directory, worktree }) => {
        return {
          event: async ({ event }) => {
            // Send notification on session completion
            if (event.type === "session.idle") {
              await $`${notifyCmd}`;
            }
          },
        }
      }
    '';
}
