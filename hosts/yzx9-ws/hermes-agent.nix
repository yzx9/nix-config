{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

let
  inherit (pkgs.stdenvNoCC.hostPlatform) system;
in
{
  age.secrets.hermes-env.file = ../../secrets/hermes-env.age;

  home.packages = with pkgs; [
    olm # e2ee
    agent-browser
  ];

  programs.hermes-agent = {
    enable = true;

    package = inputs.hermes-agent.packages.${system}.default.override {
      extraDependencyGroups = [ "matrix" ];
    };

    environmentFiles = [
      config.age.secrets.hermes-env.path
    ];

    settings = {
      #################################
      #            models
      #################################
      custom_providers = [
        {
          name = "uni";
          base_url = "https://maas-api.ai-yuanjing.com/openapi/compatible-mode/v1";
          api_mode = "chat_completions";
          key_env = "YUANJING_API_KEY";
        }
      ];

      model = {
        provider = "zai";
        default = "glm-5.2";
        base_url = "https://open.bigmodel.cn/api/coding/paas/v4";
        context_length = 1000000;
      };

      fallback_providers = {
        provider = "custom:uni";
        model = "glm-5.2";
        context_length = 1000000;
      };

      auxiliary = {
        compression = {
          provider = "zai";
          model = "glm-5.2";
          base_url = "https://open.bigmodel.cn/api/coding/paas/v4";

          fallback_chain = {
            provider = "custom:uni";
            model = "glm-5.2";
          };
        };
      };

      #################################
      #           channels
      #################################

      display = {
        compact = false;
        busy_input_mode = "queue"; # steer, queue, or interrupt (default)
        personality = "kawaii";
      };

      matrix = {
        require_mention = false; # Require @mention in rooms (default: true)
        auto_thread = true; # Auto-create threads for responses (default: true)
        dm_auto_thread = true; # bug: NousResearch/hermes-agent#24114
        encryption = true; # End-to-End Encryption
      };

      #################################
      #           functions
      #################################
      agent = {
        max_turns = 60;
        verbose = false;
      };

      toolsets = [ "all" ];

      compression = {
        enabled = true;
        threshold = 0.85;
      };

      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };

      terminal = {
        backend = "local";
        cwd = ".";
        timeout = 180;
      };

      web.backend = "tavily";
    };

    mcpServers = {
      context7 = {
        url = "https://mcp.context7.com/mcp";
        headers.CONTEXT7_API_KEY = "\${CONTEXT7_API_KEY}";
        timeout = 180;
      };

      github = {
        command = lib.getExe pkgs.github-mcp-server;
        args = [ "stdio" ];
        env.GITHUB_PERSONAL_ACCESS_TOKEN = "\${GITHUB_PERSONAL_ACCESS_TOKEN}";
      };

      playwright = {
        command = lib.getExe pkgs.playwright-mcp;
        args = [
          "--headless"
          "--isolated"
        ];
      };

      zai-vision = {
        command = lib.getExe pkgs.yzx9.zai-mcp-server;
        env = {
          Z_AI_API_KEY = "\${GLM_API_KEY}";
          Z_AI_MODE = "ZHIPU";
        };
      };

      zai-web-search = {
        url = "https://open.bigmodel.cn/api/mcp/web_search_prime/mcp";
        headers.Authorization = "Bearer \${GLM_API_KEY}";
        timeout = 180;
      };

      zai-web-reader = {
        url = "https://open.bigmodel.cn/api/mcp/web_reader/mcp";
        headers.Authorization = "Bearer \${GLM_API_KEY}";
        timeout = 180;
      };

      # zotero-mcp = {
      #   command = lib.getExe pkgs.yzx9.zotero-mcp;
      #   args = [ "serve" ];
      #   env = {
      #     ZOTERO_API_KEY = "\${ZOTERO_API_KEY}";
      #     ZOTERO_LIBRARY_ID = "\${ZOTERO_LIBRARY_ID}";
      #   };
      # };

      # zai-zread = {
      #   url = "https://open.bigmodel.cn/api/mcp/zread/mcp";
      #   headers.Authorization = "Bearer \${GLM_API_KEY}";
      #   timeout = 180;
      # };
    };

    documents.".hermes/SOUL.md" = ''
      # Personality
      You are Hermes Agent, an intelligent AI assistant created by Nous Research. You are helpful, knowledgeable,
      and direct. You assist users with a wide range of tasks including answering questions, writing and editing
      code, analyzing information, creative work, and executing actions via your tools. You communicate clearly,
      admit uncertainty when appropriate, and prioritize being genuinely useful over being verbose unless otherwise
      directed below. Be targeted and efficient in your exploration and investigations.

      ## Style
      - Be direct without being cold
      - Prefer substance over filler
      - Push back when something is a bad idea
      - Admit uncertainty plainly
      - Keep explanations compact unless depth is useful

      ## What to avoid
      - Sycophancy
      - Hype language
      - Repeating the user's framing if it's wrong
      - Overexplaining obvious things

      ## Defaults
      - When searching for or verifying relevant news facts, it is necessary to consider both results from the
        China region (using zai-web-search) and results from the international scope (using tavily via web_search).
      - Prefer simple systems over clever systems
    '';
  };
}
