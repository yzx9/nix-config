{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

{
  imports = [ inputs.self.homeManagerModules.paseo ];

  age.secrets = lib.mkIf config.purpose.dev.enable {
    "paseo".file = ../../secrets/paseo.age;
  };

  programs.paseo = {
    enable = config.purpose.dev.enable;

    package = pkgs.writeShellApplication {
      name = "paseo";

      runtimeInputs = with pkgs.yzx9; [
        with-secrets
        paseo
      ];

      text = ''
        with-secrets "${config.age.secrets."paseo".path}" "${config.age.secrets."llm-api-keys".path}" \
          --allow PASEO_RELAY_PUBLIC_ENDPOINT \
          --map GLM_CODING_API_KEY ANTHROPIC_AUTH_TOKEN \
          -- paseo "$@"
      '';
    };

    relay = {
      enable = true;
      endpoint = "10.6.141.234:51185";
    };

    settings = {
      version = 1;

      daemon = {
        listen = "127.0.0.1:6767";
        cors.allowedOrigins = [ "https://app.paseo.sh" ];
        relay.enabled = true;
      };

      app.baseUrl = "https://app.paseo.sh";

      agents.providers = {
        copilot.enabled = false;
        pi.enabled = false;

        # GLM via Z.AI / 智谱 (Anthropic-compatible API)
        glm = {
          extends = "claude";
          label = "GLM (Z.AI)";
          env = {
            ANTHROPIC_BASE_URL = "https://open.bigmodel.cn/api/anthropic";
            API_TIMEOUT_MS = "3000000";
          };
          disallowedTools = [ "WebSearch" ];
          models = [
            {
              id = "glm-5.1";
              label = "GLM 5.1";
              isDefault = true;
            }
            {
              id = "glm-4.7";
              label = "GLM 4.7";
            }
          ];
        };
      };
    };
  };
}
