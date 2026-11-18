# claude-code-proxy (https://github.com/raine/claude-code-proxy): local
# Anthropic-compatible proxy that lets Claude Code use subscription-backed
# providers.
#
# Data layout:
#   - declarative config  → config.json in CCP_CONFIG_DIR (non-secret settings)
#   - static secret       → runtime environment or an external package wrapper
#   - OAuth credentials   → CCP_CONFIG_DIR — written and refreshed by
#     claude-code-proxy itself; home-manager never touches it
#
# The local listener is unauthenticated by design (loopback trust)
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
  jsonFormat = pkgs.formats.json { };

  # CCP_CONFIG_DIR moves configuration *and* file-backed auth (including the
  # codex credential that would otherwise live in the macOS Keychain), so both
  # the service and `ccp-login` agree on one writable location.
  stateDir = "${config.xdg.stateHome}/claude-code-proxy";

  package = pkgs.writeShellApplication {
    name = "claude-code-proxy";

    runtimeEnv = cfg.environmentVariables // {
      CCP_CONFIG_DIR = stateDir;
    };

    text = ''
      exec ${lib.getExe cfg.package} "$@"
    '';
  };
in
{
  options.programs.claude-code-proxy = {
    enable = lib.mkEnableOption "claude-code-proxy local model proxy";

    package = lib.mkOption {
      type = lib.types.package;
      default = inputs.claude-code-proxy.packages.${system}.default;
      defaultText = "inputs.claude-code-proxy.packages.\${system}.default";
      description = "The claude-code-proxy package to use";
    };

    environmentVariables = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Environment variables to set for the claude-code-proxy";
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf jsonFormat.type;
      default = { };
      description = "Settings to pass to the claude-code-proxy (stored in the Nix store; do not include secrets)";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ package ];

    # Only the directory; auth.json and logs below are CCP's own runtime
    # state — redeploys must never clobber live (rotating) tokens.
    home.activation.claudeCodeProxyDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      install -d -m 700 ${stateDir}
    '';

    xdg.stateFile."claude-code-proxy/config.json".source =
      jsonFormat.generate "claude-code-proxy-config.json" cfg.settings;

    systemd.user.services.claude-code-proxy = lib.mkIf pkgs.stdenvNoCC.hostPlatform.isLinux {
      Unit.Description = "claude-code-proxy - local Anthropic-compatible model proxy";

      Service = {
        ExecStart = "${lib.getExe package} serve --no-monitor";
        Restart = "on-failure";
        RestartSec = 5;
      };

      Install.WantedBy = [ "default.target" ];
    };

    launchd.agents.claude-code-proxy = lib.mkIf pkgs.stdenvNoCC.hostPlatform.isDarwin {
      enable = true;
      config = {
        ProgramArguments = [
          (lib.getExe package)
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
