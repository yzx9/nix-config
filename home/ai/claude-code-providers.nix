# Per-provider profiles for the `claude` wrapper: pure data, imported by
# home/ai/claude-code.nix (which turns them into generated settings JSON) and
# by anything else that needs to talk to the same provider with the same
# credentials (e.g. hosts/yzx9-ws/cc-keepalive.nix). The base URL, model
# aliases (and the proxy, when set) are written into a generated settings JSON
# passed via `claude --settings`, so they are read by every session type —
# including background workers, which no longer inherit these from the
# dispatch shell. The API key itself is never written to disk; it is resolved
# at call time via `apiKeyHelper`.
{
  glm = {
    key = "GLM_CODING_API_KEY";
    settings = {
      env = {
        ANTHROPIC_BASE_URL = "https://open.bigmodel.cn/api/anthropic";
        ANTHROPIC_DEFAULT_OPUS_MODEL = "glm-5.3[1m]";
        ANTHROPIC_DEFAULT_SONNET_MODEL = "glm-5.3[1m]";
        ANTHROPIC_DEFAULT_HAIKU_MODEL = "glm-5.3-flash[1m]";
        CLAUDE_CODE_AUTO_COMPACT_WINDOW = "400000"; # Auto-compact on 400k boundary, but not 1M
      };

      attribution.commit = "Assisted-by: Claude-Code:GLM-5.3";
    };
  };
  uni = {
    key = "UNI_YUANJING_API_KEY";
    settings = {
      env = {
        ANTHROPIC_BASE_URL = "https://maas-api.ai-yuanjing.com/openapi/compatible-mode";
        ANTHROPIC_DEFAULT_OPUS_MODEL = "glm-5.2";
        ANTHROPIC_DEFAULT_SONNET_MODEL = "glm-5";
        ANTHROPIC_DEFAULT_HAIKU_MODEL = "glm-5";
        # Disable 1M token context for 3rd party models
        CLAUDE_CODE_DISABLE_1M_CONTEXT = "1";
      };

      attribution.commit = "Assisted-by: Claude-Code:GLM-5";
    };
  };
}
