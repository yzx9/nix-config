{
  config,
  pkgs,
  lib,
  ...
}:

let
  skills = import ./skills.nix { inherit pkgs; };
  isDarwin = pkgs.stdenvNoCC.hostPlatform.isDarwin;
  codex-notify = pkgs.replaceVars ./codex-notify.py {
    TERMINAL_NOTIFIER = if isDarwin then "${pkgs.terminal-notifier}/bin/terminal-notifier" else "";
    NOTIFY_SEND = if isDarwin then "" else "${lib.getBin pkgs.libnotify}/bin/notify-send";
  };

  codex' = pkgs.writeShellApplication {
    name = "codex";

    derivationArgs = {
      inherit (pkgs.codex) pname version;
    };

    runtimeInputs = [
      pkgs.yzx9.with-secrets
      pkgs.codex
    ];

    runtimeEnv.HTTPS_PROXY = config.proxy.http;

    text = ''
      with-secrets "${config.age.secrets."llm-api-keys".path}" \
        --allow CONTEXT7_API_KEY \
        --allow GITHUB_PAT \
        -- codex "$@"
    '';
  };
in
{
  programs.codex = {
    enable = config.purpose.dev.enable;
    package = codex';
    inherit skills;

    settings = {
      model = "gpt-5.4";
      notice.model_migrations."gpt-5.3-codex" = "gpt-5.4";

      sandbox_mode = "workspace-write";
      approval_policy = "untrusted";
      allow_login_shell = false;

      notify = [
        "${pkgs.python3}"
        "${codex-notify}"
      ];

      mcp_servers = {
        context7 = {
          url = "https://mcp.context7.com/mcp";
          env_http_headers.CONTEXT7_API_KEY = "\$CONTEXT7_API_KEY";
        };

        github = {
          url = "https://api.githubcopilot.com/mcp/";
          bearer_token_env_var = "GITHUB_PAT";
        };

        playwright.command = lib.getExe pkgs.playwright-mcp;
      };
    };
  };
}
