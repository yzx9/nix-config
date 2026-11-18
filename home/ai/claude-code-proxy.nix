{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

let
  inherit (pkgs.stdenvNoCC.hostPlatform) system;

  # The GLM key, single-sourced from the age file. NB: agenix `.path` is a
  # runtime-expanded value — keep it double-quoted so the shell expands it.
  keyFile = config.age.secrets."llm-api-keys".path;

  pkg = inputs.claude-code-proxy.packages.${system}.default;

  # Personal policy wrapper: resolve the GLM key from the age-decrypted file
  # at process start — never in the store, never in unit files. The generic
  # module handles CCP_CONFIG_DIR and the shared CLI/service environment.
  # umask 077 keeps CCP-written state (auth.json, logs) 0600. Invoke the
  # upstream binary by absolute path so the wrapper cannot recurse.
  cliWrapper = pkgs.writeShellApplication {
    name = "claude-code-proxy";

    runtimeInputs = [ pkgs.yzx9.with-secrets ];

    text = ''
      umask 077
      # Fail fast, but only on serve: with-secrets merely *warns* on a
      # missing key, yet half the model slots are GLM — a silently key-less
      # service would 401 mid-session.
      if [ "''${1-}" = "serve" ] && ! grep -Eq '^(export )?GLM_CODING_API_KEY=.' "${keyFile}"; then
        echo "claude-code-proxy: GLM_CODING_API_KEY missing or empty in ${keyFile}" >&2
        exit 1
      fi
      exec with-secrets "${keyFile}" \
        --map GLM_CODING_API_KEY CCP_OPENCODE_API_KEY \
        -- ${lib.getExe pkg} "$@"
    '';
  };
in
{
  programs.claude-code-proxy = {
    enable = config.my.host.dev.ai.enable;
    package = cliWrapper;

    environmentVariables = lib.optionalAttrs (config.my.proxy.httpPublic != null) {
      HTTPS_PROXY = config.my.proxy.httpPublic;
      https_proxy = config.my.proxy.httpPublic;

      # GLM is a domestic endpoint — pin it direct instead of gambling on
      # the proxy's routing rules; loopback stays exempt as always.
      NO_PROXY = "localhost,127.0.0.1,open.bigmodel.cn";
      no_proxy = "localhost,127.0.0.1,open.bigmodel.cn";
    };

    settings = {
      autoReviewModel = "gpt-6-luna";

      # GLM rides the generic opencode provider: same key, its OpenAI-
      # compatible endpoint, glm-* ids already in the static model catalog.
      opencode.baseUrl = "https://open.bigmodel.cn/api/coding/paas/v4";
    };
  };

  # The wrapper reads the age-decrypted llm-api-keys file.
  systemd.user.services =
    lib.mkIf (pkgs.stdenvNoCC.hostPlatform.isLinux && config.programs.claude-code-proxy.enable)
      {
        claude-code-proxy.Unit = {
          After = [ "agenix.service" ];
          Wants = [ "agenix.service" ];
        };
      };
}
