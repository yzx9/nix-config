{
  config,
  pkgs,
  lib,
  ...
}:

let
  hasProxy = config.proxy.httpPublicProxy != null;
  toYAML = lib.generators.toYAML { };
  toJSON = lib.generators.toJSON { };

  # Inject api keys in runtime
  goose-cli' = pkgs.writeShellApplication {
    name = "goose";
    runtimeInputs = [
      pkgs.with-secrets
      pkgs.goose-cli
    ];
    text = ''
      export GOOSE_DISABLE_KEYRING=1
      export LANGFUSE_URL=https://us.cloud.langfuse.com
      export LANGFUSE_INIT_PROJECT_PUBLIC_KEY=pk-lf-84b79195-3106-473a-bdbf-448e146a206d

      ${lib.optionalString hasProxy "export HTTPS_PROXY=${config.proxy.httpPublicProxy}"}

      with-secrets \
        "${config.age.secrets."llm-api-keys".path}" \
        "${config.age.secrets."langfuse-secret-key".path}" \
        --allow GLM_CODING_API_KEY \
        --allow GOOGLE_API_KEY \
        --allow SILICONFLOW_API_KEY \
        --allow OPENROUTER_API_KEY \
        --map langfuse-goose LANGFUSE_INIT_PROJECT_SECRET_KEY \
        -- goose "$@"
    '';
  };
in
lib.mkIf config.purpose.dev.enable {
  age.secrets = {
    "llm-api-keys".file = ../secrets/llm-api-keys.age;
    "langfuse-secret-key".file = ../secrets/langfuse-secret-key.age;
  };

  home.packages = [ goose-cli' ];

  # goose config file
  xdg.configFile = {
    "goose/config.yaml".text = toYAML {
      # Model Configuration
      GOOSE_PROVIDER = "custom_glm_coding";
      GOOSE_MODEL = "glm-4.7";
      GOOSE_TEMPERATURE = 0.7;

      # Planning Configuration
      GOOSE_PLANNER_PROVIDER = "openrouter";
      GOOSE_PLANNER_MODEL = "google/gemini-3-pro-preview";

      # Tool Configuration
      GOOSE_MODE = "completely_autonomous"; # completely_autonomous, manual_approval, smart_approve, chat_only
      GOOSE_TOOLSHIM = true;
      GOOSE_CLI_MIN_PRIORITY = 0.8; # output verbosity: high -> 0.8, medium -> 0.2, all -> 0.0

      # Environment Configuration
      extensions = {
        developer = {
          bundled = true;
          enabled = true;
          type = "builtin";
          name = "developer";
          display_name = "Developer Tools";
          timeout = 300;
        };

        computercontroller = {
          enabled = true;
          type = "builtin";
          name = "computercontroller";
          display_name = "Computer Controller";
          description = null;
          timeout = 300;
          bundled = true;
        };
      };
    };

    "goose/custom_providers/custom_siliconflow.json".text = toJSON {
      name = "custom_siliconflow";
      engine = "openai";
      display_name = "SiliconFlow";
      description = "Custom SiliconFlow provider";
      api_key_env = "SILICONFLOW_API_KEY";
      base_url = "https://api.siliconflow.cn/v1/chat/completions";
      models = [
        {
          name = "zai-org/glm-4.6";
          context_limit = 128000;
          input_token_cost = null;
          output_token_cost = null;
          currency = null;
          supports_cache_control = null;
        }
      ];
      headers = null;
      timeout_seconds = null;
      supports_streaming = true;
    };

    "goose/custom_providers/custom_glm_coding.json".text = toJSON {
      name = "custom_glm_coding";
      engine = "anthropic";
      display_name = "GLM Coding";
      description = "Custom GLM Coding provider";
      api_key_env = "GLM_CODING_API_KEY";
      base_url = "https://open.bigmodel.cn/api/anthropic";
      models = [
        {
          name = "glm-4.7";
          context_limit = 200000;
          input_token_cost = 0;
          output_token_cost = 0;
          currency = null;
          supports_cache_control = null;
        }
      ];
      headers = null;
      timeout_seconds = null;
      supports_streaming = true;
    };
  };
}
