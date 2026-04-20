{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    inputs.self.homeManagerModules.default
  ];

  age.secrets.hermes-env.file = ../../secrets/hermes-env.age;

  home.packages = with pkgs; [ olm ]; # e2ee

  programs.hermes-agent = {
    enable = true;

    environmentFiles = [
      config.age.secrets.hermes-env.path
    ];

    settings = {
      model = {
        provider = "zai";
        default = "GLM-5.1";
        base_url = "https://open.bigmodel.cn/api/coding/paas/v4";
      };

      toolsets = [ "all" ];
      max_turns = 100;

      terminal = {
        backend = "local";
        cwd = ".";
        timeout = 180;
      };

      compression = {
        enabled = true;
        threshold = 0.85;
        summary_model = "GLM-5.1";
      };

      display = {
        compact = false;
        personality = "kawaii";
      };

      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };

      agent = {
        max_turns = 60;
        verbose = false;
      };

      matrix = {
        require_mention = false; # Require @mention in rooms (default: true)
        auto_thread = true; # Auto-create threads for responses (default: true)
        encryption = true; # End-to-End Encryption
      };
    };

    mcpServers = {
      context7 = {
        url = "https://mcp.context7.com/mcp";
        headers.CONTEXT7_API_KEY = "\${CONTEXT7_API_KEY}";
        timeout = 180;
      };

      github = {
        url = "https://api.githubcopilot.com/mcp/";
        headers.Authorization = "Bearer \${GITHUB_PAT}";
        timeout = 180;
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

      zotero-mcp = {
        command = lib.getExe pkgs.yzx9.zotero-mcp;
        args = [ "serve" ];
        env = {
          ZOTERO_API_KEY = "\${ZOTERO_API_KEY}";
          ZOTERO_LIBRARY_ID = "\${ZOTERO_LIBRARY_ID}";
        };
      };

      zai-zread = {
        url = "https://open.bigmodel.cn/api/mcp/zread/mcp";
        headers.Authorization = "Bearer \${GLM_API_KEY}";
        timeout = 180;
      };
    };
  };
}
