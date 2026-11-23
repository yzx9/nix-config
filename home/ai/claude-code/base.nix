{
  config,
  pkgs,
  lib,
  ...
}:

let
  enableSearch = false;

  hasProxy = config.my.proxy.httpPublic != null;

  # One generated `settings.json` per provider: the profile `env`.
  # Deep-merged with the HM-managed user settings, so
  # permissions/sandbox/hooks/etc. are preserved.
  settings = pkgs.writeText "claude-code-settings.json" (
    builtins.toJSON {
      env = {
        # All model traffic goes through the local claude-code-proxy
        ANTHROPIC_BASE_URL = "http://127.0.0.1:18765";
        ANTHROPIC_AUTH_TOKEN = "unused"; # loopback proxy needs no credential
      };
    }
  );

  # Claude Code wrapper: runs with the HM-managed settings below (the local
  # claude-code-proxy, which needs no client credential — hence the literal
  # `ANTHROPIC_AUTH_TOKEN=unused` there). `with-secrets` only exposes
  # non-Anthropic secrets (MCP tokens) to the process. The upstream binary is
  # invoked by absolute path to avoid recursing into this wrapper, and any
  # extra args from the caller (historically `--plugin-dir` from the HM
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
      with-secrets "${config.age.secrets."llm-api-keys".path}" \
        --allow TAVILY_API_KEY \
        --allow ZOTERO_API_KEY \
        --allow ZOTERO_LIBRARY_ID \
        -- \
        "${lib.getExe pkgs.claude-code}" "$@" \
        --settings "${toString settings}"
    '';
  };

  defaultModel = "gpt-6.2-astra[1m]";
  attributions = [
    "GPT-6.2"
    "GLM-5.3"
  ];
  models = [
    {
      model = "gpt-6.2-astra";
      label = "astra";
      effortLevel = "high"; # "low", "medium", "high", "xhigh", "max"
      autoCompactWindow = 400000;
      behavesAs = "fable";
    }

    {
      model = "gpt-6.2-sol";
      label = "sol";
      effortLevel = "high";
      autoCompactWindow = 400000;
      behavesAs = "opus";
    }

    {
      model = "glm-5.3";
      label = "glm";
      effortLevel = "high";
      autoCompactWindow = 400000;
      behavesAs = "sonnet";
    }

    {
      model = "glm-5.3-flash";
      label = "glm-flash";
      effortLevel = "high";
      autoCompactWindow = 400000;
      behavesAs = "haiku";
    }
  ];
in
{
  programs.claude-code = {
    enable = config.my.host.dev.ai.enable;
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
        # Upstream recommendation: never replay a broken stream as one shot — it can duplicate tool calls.
        CLAUDE_CODE_DISABLE_NONSTREAMING_FALLBACK = 1;
        # https://code.claude.com/docs/zh-CN/auto-mode-classifier-billing
        CLAUDE_CODE_AUTO_MODE_SERVER = 0;
      }
      // (lib.listToAttrs (
        lib.map (value: {
          name = "ANTHROPIC_DEFAULT_${lib.toUpper value.behavesAs}_MODEL";
          value = value.model;
        }) models
      ));

      theme = "dark";
      editorMode = "vim";
      tui = "fullscreen";
      disableDeepLinkRegistration = "disable"; # claude-cli:// and Claude Code URL Handler.app
      useAutoModeDuringPlan = true;
      skipAutoPermissionPrompt = true;

      model = defaultModel;
      fastMode = false;
      modelSettings = lib.listToAttrs (
        lib.map (item: {
          name = item.model;
          value = { inherit (item) effortLevel autoCompactWindow; };
        }) models
      );
      modelPicker = {
        replaceBuiltInOptions = true;
        options = lib.map (item: {
          model = item.model + "[1m]";
          inherit (item) label behavesAs;
        }) models;
      };

      attribution = {
        pr = ""; # To hide attribution, set to empty strings.
        commit = lib.join "\n" (lib.map (item: "Assisted-by: Claude-Code:${item}") attributions);
      };

      sandbox.network = lib.optionalAttrs hasProxy {
        httpProxyPort = config.my.proxy.httpPublicPort;
      };
    };

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
  };
}
