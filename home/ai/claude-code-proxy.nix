{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

let
  inherit (pkgs.stdenvNoCC.hostPlatform) system;

  enable = config.my.host.dev.ai.enable;

  # The GLM key, single-sourced from the age file. NB: agenix `.path` is a
  # runtime-expanded value — keep it double-quoted so the shell expands it.
  keyFile = config.age.secrets."llm-api-keys".path;

  pkg = inputs.claude-code-proxy.packages.${system}.default;

  # Personal policy wrapper: resolve the GLM key from the age-decrypted file
  # at process start — never in the store, never in unit files. The generic
  # module handles CCP_CONFIG_DIR and the shared CLI/service environment.
  # umask 077 keeps CCP-written state (auth.json, logs) 0600. Invoke the
  # upstream binary by absolute path so the wrapper cannot recurse.
  package = pkgs.writeShellApplication {
    name = "claude-code-proxy";

    runtimeInputs = [ pkgs.yzx9.with-secrets ];

    text = ''
      umask 077
      exec with-secrets "${keyFile}" \
        --map GLM_CODING_API_KEY CCP_OPENCODE_API_KEY \
        -- ${lib.getExe pkg} "$@"
    '';
  };
in
{
  programs.claude-code-proxy = {
    inherit enable package;

    environmentVariables = lib.optionalAttrs (config.my.proxy.httpPublic != null) {
      HTTPS_PROXY = config.my.proxy.httpPublic;
      https_proxy = config.my.proxy.httpPublic;
    };

    settings = {
      bindAddress = "127.0.0.1";
      port = 18765;
      autoReviewModel = "gpt-6-luna";

      # GLM rides the generic opencode provider: same key, its OpenAI-
      # compatible endpoint, glm-* ids already in the static model catalog.
      opencode.baseUrl = "https://open.bigmodel.cn/api/coding/paas/v4";
    };
  };

  # The wrapper reads the age-decrypted llm-api-keys file.
  systemd.user.services = lib.mkIf (enable && pkgs.stdenvNoCC.hostPlatform.isLinux) {
    claude-code-proxy.Unit = {
      After = [ "agenix.service" ];
      Wants = [ "agenix.service" ];
    };
  };
}
