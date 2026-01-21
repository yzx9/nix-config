{
  config,
  pkgs,
  # lib,
  ...
}:

let
  # hasProxy = config.proxy.httpPublicProxy != null;

  # Claude Code wrapper script to inject API keys at runtime
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
in
{
  # See claude-code.nix
  # age.secrets."llm-api-keys".file = ../secrets/llm-api-keys.age;

  programs.opencode = {
    enable = config.purpose.dev.enable;
    package = opencode';

    settings = {
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
        };
      };
    };

    commands = {
      changelog = ''
        ---
        description: Update CHANGELOG.md with new entry
        ---

        Parse the version, change type, and message from the input and update the CHANGELOG.md file
        accordingly.
      '';

      commit = ''
        ---
        description: Create a git commit with proper message
        ---

        ## Context

        - Current git status: !`git status`
        - Current git diff: !`git diff HEAD`
        - Recent commits: !`git log --oneline -5`

        ## Task

        Based on the changes above, run the necessary check steps, including formatting and testing
        if applicable. Then stage the changes and create a concise, descriptive git commit message.

        ## Notes

        - Check that all tests pass and code is properly formatted before committing.
        - Check unstaged changes. If there are no staged changes, or if the unstaged changes are
          only minor formatting or comment fixes, stage them. Otherwise, do not modify the current
          staged changes and proceed to the next step.
        - Analyze the changes to determine the appropriate commit type
        - Write a commit message follows commit standards as per the project's guidelines.
      '';
    };
  };
}
