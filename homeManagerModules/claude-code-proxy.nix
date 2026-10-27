# claude-code-proxy (https://github.com/raine/claude-code-proxy): local
# Anthropic-compatible proxy that lets Claude Code use subscription-backed
# providers. Here: Codex via ChatGPT OAuth (`claude-code-proxy codex auth
# login`, per-machine tokens) and GLM via its OpenAI-compatible endpoint,
# borrowing the generic opencode provider (baseUrl + apiKey; glm-* ids route
# to it and are translated through the same openai_compat layer as kimi/grok).
#
# Data layout:
#   - declarative config  → none needed; everything is env (all optional
#     upstream: defaults 127.0.0.1:18765, codex as alias provider)
#   - static secret       → GLM key, single-sourced from llm-api-keys.age and
#     injected at process start via `with-secrets --map`
#   - OAuth credentials   → ~/.local/state/claude-code-proxy/ (CCP_CONFIG_DIR;
#     file-backed auth on every platform, darwin included) — written and
#     refreshed by claude-code-proxy itself; home-manager never touches it
#
# The local listener is unauthenticated by design (loopback trust); Claude
# Code sends a literal `ANTHROPIC_AUTH_TOKEN=unused`, see ./claude-code.nix.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs.stdenvNoCC.hostPlatform) system;

  cfg = config.programs.claude-code-proxy;

  # CCP_CONFIG_DIR moves configuration *and* file-backed auth (including the
  # codex credential that would otherwise live in the macOS Keychain), so both
  # the service and `ccp-login` agree on one writable location.
  stateDir = "${config.home.homeDirectory}/.local/state/claude-code-proxy";

  # Non-secret process environment — single source shared by the service
  # wrapper and ccp-login, so OAuth flows and serving always agree.
  #
  # NB: requests carrying a native claude-*/anthropic-style model id (anything
  # not covered by Claude Code's four ANTHROPIC_DEFAULT_*_MODEL slots) fall
  # through to CCP's alias provider, which defaults to codex — upstream
  # accepts only `codex`/`kimi` there, so before `ccp-login codex` such
  # requests fail on the missing codex credential even though GLM is keyed.
  serviceEnv = {
    CCP_CONFIG_DIR = stateDir;
    # GLM rides the generic opencode provider: same key, its OpenAI-
    # compatible endpoint, glm-* ids already in the static model catalog.
    CCP_OPENCODE_BASE_URL = "https://open.bigmodel.cn/api/coding/paas/v4";
    # GLM is a domestic endpoint — pin it direct (0.2s measured) instead of
    # gambling on the proxy's routing rules; loopback stays exempt as always.
    NO_PROXY = "localhost,127.0.0.1,open.bigmodel.cn";
    no_proxy = "localhost,127.0.0.1,open.bigmodel.cn";
  }
  // (lib.optionalAttrs (config.my.proxy.httpPublic != null) {
    # ChatGPT/Codex upstream needs the auto-routing public proxy (12345):
    # the plain 10087 instance failed to route chatgpt.com/bigmodel.cn on
    # 2026-10-28. Dual-case on purpose: the codex API client reads both
    # spellings, but the auth subsystem (PKCE login, device flow, token
    # refresh) uses bare reqwest clients that only honor lowercase in this
    # build — verified empirically (uppercase-only login failed at the
    # oauth/token exchange). Same precedent as the tavily-mcp env.
    HTTPS_PROXY = config.my.proxy.httpPublic;
    https_proxy = config.my.proxy.httpPublic;
  });

  exportEnv = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (k: v: "export ${k}=${lib.escapeShellArg v}") serviceEnv
  );

  # The GLM key, single-sourced from the age file. NB: agenix `.path` is a
  # runtime-expanded value — keep it double-quoted so the shell expands it.
  keyFile = config.age.secrets."llm-api-keys".path;

  # One same-name wrapper fronts every claude-code-proxy invocation (same
  # convention as the claude/codex wrappers): it pins CCP_CONFIG_DIR so auth,
  # monitor and serve always agree on the state dir, routes upstream traffic
  # through the local proxy, and resolves the GLM key from the age-decrypted
  # file at process start — never in the store, never in unit files. umask 077
  # keeps CCP-written state (auth.json, logs) 0600. The upstream binary is
  # invoked by absolute path so the wrapper does not recurse into itself.
  cliWrapper = pkgs.writeShellApplication {
    name = "claude-code-proxy";

    runtimeInputs = [ pkgs.yzx9.with-secrets ];

    text = ''
      ${exportEnv}
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
        -- ${lib.getExe cfg.package} "$@"
    '';
  };
in
{
  options.programs.claude-code-proxy = {
    enable = (lib.mkEnableOption "claude-code-proxy local model proxy") // {
      # AI coding tools live on daily personal machines only (yzx9-ws/mbp).
      default = config.my.host.dev.ai.enable;
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = inputs.claude-code-proxy.packages.${system}.default;
      defaultText = "inputs.claude-code-proxy.packages.\${system}.default";
      description = "The claude-code-proxy package to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cliWrapper ];

    # Only the directory; auth.json and logs below are CCP's own runtime
    # state — redeploys must never clobber live (rotating) tokens.
    home.activation.claudeCodeProxyDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      install -d -m 700 ${stateDir}
    '';

    systemd.user.services.claude-code-proxy = lib.mkIf pkgs.stdenvNoCC.hostPlatform.isLinux {
      Unit = {
        Description = "claude-code-proxy - local Anthropic-compatible model proxy";
        # The wrapper reads the age-decrypted llm-api-keys file.
        After = [ "agenix.service" ];
        Wants = [ "agenix.service" ];
      };

      Service = {
        ExecStart = "${lib.getExe cliWrapper} serve --no-monitor";
        Restart = "on-failure";
        RestartSec = 5;
      };

      Install.WantedBy = [ "default.target" ];
    };

    launchd.agents.claude-code-proxy = lib.mkIf pkgs.stdenvNoCC.hostPlatform.isDarwin {
      enable = true;
      config = {
        ProgramArguments = [
          (lib.getExe cliWrapper)
          "serve"
          "--no-monitor"
        ];
        RunAtLoad = true;
        # Restart on failure (non-zero / crash exit).
        KeepAlive.SuccessfulExit = false;
        ThrottleInterval = 5;
        ProcessType = "Background";
        # Logs: CCP writes ~/.local/state/claude-code-proxy/proxy.log itself.
      };
    };
  };
}
