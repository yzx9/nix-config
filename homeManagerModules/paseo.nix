{
  config,
  pkgs,
  lib,
  ...
}:

# Paseo — self-hosted daemon for AI coding agents (Claude Code, Codex, OpenCode).
#
# Architecture:
#   ┌───────────┐     ┌──────────────┐     ┌─────────┐
#   │ Mobile App│────→│ relay server │←────│ daemon  │
#   │ or CLI    │ ws  │              │ ws  │ (local) │
#   └───────────┘     └──────────────┘     └─────────┘
#
# - daemon: runs on each machine, manages AI agents
# - relay:  WebSocket broker, bridges mobile/remote clients to daemons (E2E encrypted)
#
# CLI connects directly:   `paseo ls --host localhost:6767`
# CLI connects via relay:  `paseo ls --host 'https://app.paseo.sh/#offer=eyJ...'`
# Pair a mobile device:    `paseo daemon pair`

let
  cfg = config.programs.paseo;

  # Provider submodule shared by custom providers
  customProviderSubmodule = {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      extends = lib.mkOption {
        type = lib.types.str;
        description = "Built-in provider to extend.";
      };
      label = lib.mkOption { type = lib.types.str; };
      env = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
      };
      models = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [ ];
      };
      disallowedTools = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
    };
  };

  # Built-in provider submodule
  builtInProviderSubmodule = {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      package = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = null;
        description = "Package providing the agent executable.";
      };
      env = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
      };
      models = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [ ];
      };
      disallowedTools = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
    };
  };
in
{
  options.programs.paseo = {
    enable = lib.mkEnableOption "Paseo, a self-hosted daemon for AI coding agents";

    package = lib.mkPackageOption pkgs [ "yzx9" "paseo" ] { };

    addr = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address for the Paseo daemon to bind to.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 6767;
      description = "Port for the Paseo daemon to listen on.";
    };

    hostnames = lib.mkOption {
      type = lib.types.either (lib.types.enum [ true ]) (lib.types.listOf lib.types.str);
      default = [ ];
      example = [
        ".example.com"
        "myhost.local"
      ];
      description = ''
        Hostnames the Paseo daemon accepts in the Host header (DNS rebinding protection).
        Set to `true` to allow any host (not recommended).
      '';
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.dataHome}/paseo";
      defaultText = lib.literalExpression ''"''${config.xdg.dataHome}/paseo"'';
      description = "Directory for Paseo state (PASEO_HOME).";
    };

    relay = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to enable the relay connection for remote access.";
      };

      endpoint = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "localhost:8411";
        description = "Relay address the daemon connects to.";
      };

      publicEndpoint = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Public relay address used in pairing URLs. Defaults to endpoint.";
      };

      useTls = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Use wss:// for the relay connection.";
      };
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Extra environment variables for the Paseo daemon.";
    };

    # Declarative config.json generation.
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        Full Paseo config.json structure. Written to `dataDir/config.json`.
        Note: `agents.providers` is auto-generated from the `providers` option.
      '';
    };

    # ── Provider packages & config.json generation ──────────────────────

    providers = {
      claude = lib.mkOption {
        type = lib.types.submodule builtInProviderSubmodule;
        default = {
          enable = config.programs.claude-code.enable;
          package =
            if config.programs.claude-code.enable then config.programs.claude-code.finalPackage else null;
        };
        defaultText = lib.literalExpression "Auto-detected from programs.claude-code";
        description = "Claude Code provider.";
      };

      codex = lib.mkOption {
        type = lib.types.submodule builtInProviderSubmodule;
        default = {
          enable = config.programs.codex.enable;
          package = if config.programs.codex.enable then config.programs.codex.package else null;
        };
        defaultText = lib.literalExpression "Auto-detected from programs.codex";
        description = "Codex provider.";
      };

      opencode = lib.mkOption {
        type = lib.types.submodule builtInProviderSubmodule;
        default = {
          enable = config.programs.opencode.enable;
          package = if config.programs.opencode.enable then config.programs.opencode.package else null;
        };
        defaultText = lib.literalExpression "Auto-detected from programs.opencode";
        description = "OpenCode provider.";
      };

      copilot = lib.mkOption {
        type = lib.types.submodule builtInProviderSubmodule;
        default.enable = false;
        default.package = null;
        description = "GitHub Copilot provider.";
      };

      pi = lib.mkOption {
        type = lib.types.submodule builtInProviderSubmodule;
        default.enable = false;
        default.package = null;
        description = "Pi provider.";
      };

      custom = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule customProviderSubmodule);
        default = { };
        description = "Custom providers (use `extends` to inherit from a built-in).";
      };
    };

    additionalPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Extra packages in the daemon's PATH (e.g. gh, git).";
    };

    inheritUserEnvironment = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to include the user's Home Manager profile PATH in the daemon environment.
        When enabled, agents spawned by the daemon can access all user-installed tools
        (git, ssh, etc.) without needing to add them to additionalPackages.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    let
      # Collect agent packages from enabled providers
      agentPackages =
        let
          builtInPkgs = lib.filter (p: p != null) [
            (if cfg.providers.claude.enable then cfg.providers.claude.package else null)
            (if cfg.providers.codex.enable then cfg.providers.codex.package else null)
            (if cfg.providers.opencode.enable then cfg.providers.opencode.package else null)
            (if cfg.providers.copilot.enable then cfg.providers.copilot.package else null)
            (if cfg.providers.pi.enable then cfg.providers.pi.package else null)
          ];
          # Custom providers inherit base provider's executable
          extendsPkgs = lib.unique (
            lib.filter (p: p != null) (
              lib.mapAttrsToList (
                _: p: if p.enable then cfg.providers.${p.extends}.package or null else null
              ) cfg.providers.custom
            )
          );
        in
        lib.unique (builtInPkgs ++ extendsPkgs ++ cfg.additionalPackages);

      servicePath = lib.makeBinPath ([ cfg.package ] ++ agentPackages);

      # Generate agents.providers config from providers option
      generatedProviders =
        let
          # Helper: check if a built-in provider has non-default settings
          hasSettings = p: p.env != { } || p.models != [ ] || p.disallowedTools != [ ];

          # Built-in provider config entry
          builtInEntry =
            name: p:
            if p.enable then
              lib.optionalAttrs (hasSettings p) {
                ${name} = {
                  enabled = true;
                }
                // lib.optionalAttrs (p.env != { }) { inherit (p) env; }
                // lib.optionalAttrs (p.models != [ ]) { inherit (p) models; }
                // lib.optionalAttrs (p.disallowedTools != [ ]) { inherit (p) disallowedTools; };
              }
            else
              { ${name}.enabled = false; };
        in
        lib.foldl' (acc: entry: acc // entry) { } [
          (builtInEntry "claude" cfg.providers.claude)
          (builtInEntry "codex" cfg.providers.codex)
          (builtInEntry "copilot" cfg.providers.copilot)
          (builtInEntry "opencode" cfg.providers.opencode)
          (builtInEntry "pi" cfg.providers.pi)
          # Custom providers
          (lib.mapAttrs' (
            name: p:
            lib.nameValuePair name (
              {
                extends = p.extends;
                label = p.label;
              }
              // lib.optionalAttrs (p.env != { }) { inherit (p) env; }
              // lib.optionalAttrs (p.models != [ ]) { inherit (p) models; }
              // lib.optionalAttrs (p.disallowedTools != [ ]) { inherit (p) disallowedTools; }
            )
          ) cfg.providers.custom)
        ];

      # Config file with providers merged into settings
      configFile = pkgs.writeText "paseo-config.json" (
        builtins.toJSON (
          cfg.settings
          // lib.optionalAttrs (generatedProviders != { }) {
            agents = (cfg.settings.agents or { }) // {
              providers = generatedProviders;
            };
          }
        )
      );

      # User-facing wrapper with env vars and agent packages in PATH
      wrappedPkg = pkgs.symlinkJoin {
        name = "paseo";
        paths = [ cfg.package ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild =
          let
            envArgs = [
              "--set PASEO_HOME \"${cfg.dataDir}\""
              "--set PASEO_LISTEN \"${cfg.addr}:${toString cfg.port}\""
            ]
            ++ lib.optional (
              cfg.relay.enable && cfg.relay.endpoint != null
            ) "--set PASEO_RELAY_ENDPOINT \"${cfg.relay.endpoint}\""
            ++ lib.optional (cfg.relay.enable && cfg.relay.useTls) "--set PASEO_RELAY_USE_TLS true"
            ++ lib.mapAttrsToList (k: v: "--set ${k} ${lib.escapeShellArg v}") cfg.environment;

            pathArg =
              let
                paths =
                  lib.optional (agentPackages != [ ]) (lib.makeBinPath agentPackages)
                  ++ lib.optional cfg.inheritUserEnvironment "${config.home.profileDirectory}/bin";
              in
              lib.optionalString (paths != [ ]) "--prefix PATH : ${lib.concatStringsSep ":" paths} ";
          in
          ''
            wrapProgram $out/bin/paseo ${pathArg}${lib.concatStringsSep " \\\n  " envArgs}
          '';
      };
    in
    lib.mkMerge [
      {
        home.packages = [ wrappedPkg ];
      }

      # ── Linux: systemd user service ────────────────────────────────────
      (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        systemd.user.services.paseo = {
          Unit = {
            Description = "Paseo - self-hosted daemon for AI coding agents";
            After = [ "network-online.target" ];
            Wants = [ "network-online.target" ];
          };

          Service = {
            Environment = [
              "NODE_ENV=production"
              "PASEO_HOME=${cfg.dataDir}"
              "PASEO_LISTEN=${cfg.addr}:${toString cfg.port}"
              (
                "PATH="
                + servicePath
                + lib.optionalString cfg.inheritUserEnvironment ":${config.home.profileDirectory}/bin"
                + "\${PATH:+:$PATH}"
              )
            ]
            ++ lib.optional (cfg.hostnames == true) "PASEO_HOSTNAMES=true"
            ++ lib.optional (
              lib.isList cfg.hostnames && cfg.hostnames != [ ]
            ) "PASEO_HOSTNAMES=${lib.concatStringsSep "," cfg.hostnames}"
            ++ lib.optional (
              cfg.relay.enable && cfg.relay.endpoint != null
            ) "PASEO_RELAY_ENDPOINT=${cfg.relay.endpoint}"
            ++ lib.optional (
              cfg.relay.enable && cfg.relay.publicEndpoint != null
            ) "PASEO_RELAY_PUBLIC_ENDPOINT=${cfg.relay.publicEndpoint}"
            ++ lib.optional (cfg.relay.enable && cfg.relay.useTls) "PASEO_RELAY_USE_TLS=true"
            ++ lib.mapAttrsToList (k: v: "${k}=${v}") cfg.environment;

            ExecStartPre = [
              "${pkgs.coreutils}/bin/mkdir -p ${cfg.dataDir}"
            ]
            ++ lib.optionals (cfg.settings != { } || generatedProviders != { }) [
              "${pkgs.coreutils}/bin/cp ${configFile} ${cfg.dataDir}/config.json"
            ];

            ExecStart =
              "${cfg.package}/bin/paseo daemon start"
              + " --foreground"
              + " --listen ${cfg.addr}:${toString cfg.port}"
              + " --home ${cfg.dataDir}"
              + lib.optionalString (!cfg.relay.enable) " --no-relay";

            Restart = "on-failure";
            RestartSec = 5;
          };

          Install.WantedBy = [ "default.target" ];
        };
      })

      # ── Darwin: launchd agent ──────────────────────────────────────────
      (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        launchd.agents.paseo = {
          enable = true;
          config =
            let
              daemonArgs =
                lib.escapeShellArgs [
                  "daemon"
                  "start"
                  "--foreground"
                  "--listen"
                  "${cfg.addr}:${toString cfg.port}"
                  "--home"
                  cfg.dataDir
                ]
                + lib.optionalString (!cfg.relay.enable) " --no-relay";
            in
            if cfg.settings != { } || generatedProviders != { } then
              {
                ProgramArguments = [
                  "/bin/sh"
                  "-c"
                  "mkdir -p '${cfg.dataDir}' && cp '${configFile}' '${cfg.dataDir}/config.json' && exec ${cfg.package}/bin/paseo ${daemonArgs}"
                ];
                RunAtLoad = true;
                KeepAlive.SuccessfulExit = false;
                ThrottleInterval = 5;
                WorkingDirectory = cfg.dataDir;
                EnvironmentVariables = {
                  PATH =
                    servicePath + lib.optionalString cfg.inheritUserEnvironment ":${config.home.profileDirectory}/bin";
                  NODE_ENV = "production";
                  PASEO_HOME = cfg.dataDir;
                  PASEO_LISTEN = "${cfg.addr}:${toString cfg.port}";
                }
                // lib.optionalAttrs (cfg.hostnames == true) {
                  PASEO_HOSTNAMES = "true";
                }
                // lib.optionalAttrs (lib.isList cfg.hostnames && cfg.hostnames != [ ]) {
                  PASEO_HOSTNAMES = lib.concatStringsSep "," cfg.hostnames;
                }
                // lib.optionalAttrs (cfg.relay.enable && cfg.relay.endpoint != null) {
                  PASEO_RELAY_ENDPOINT = cfg.relay.endpoint;
                }
                // lib.optionalAttrs (cfg.relay.enable && cfg.relay.publicEndpoint != null) {
                  PASEO_RELAY_PUBLIC_ENDPOINT = cfg.relay.publicEndpoint;
                }
                // lib.optionalAttrs (cfg.relay.enable && cfg.relay.useTls) {
                  PASEO_RELAY_USE_TLS = "true";
                }
                // cfg.environment;
                StandardOutPath = "${cfg.dataDir}/logs/launchd-stdout.log";
                StandardErrorPath = "${cfg.dataDir}/logs/launchd-stderr.log";
                ProcessType = "Background";
              }
            else
              {
                ProgramArguments = [
                  "${cfg.package}/bin/paseo"
                  "daemon"
                  "start"
                  "--foreground"
                  "--listen"
                  "${cfg.addr}:${toString cfg.port}"
                  "--home"
                  cfg.dataDir
                ]
                ++ lib.optional (!cfg.relay.enable) "--no-relay";
                RunAtLoad = true;
                KeepAlive.SuccessfulExit = false;
                ThrottleInterval = 5;
                WorkingDirectory = cfg.dataDir;
                EnvironmentVariables = {
                  PATH =
                    servicePath + lib.optionalString cfg.inheritUserEnvironment ":${config.home.profileDirectory}/bin";
                  NODE_ENV = "production";
                  PASEO_HOME = cfg.dataDir;
                  PASEO_LISTEN = "${cfg.addr}:${toString cfg.port}";
                }
                // lib.optionalAttrs (cfg.hostnames == true) {
                  PASEO_HOSTNAMES = "true";
                }
                // lib.optionalAttrs (lib.isList cfg.hostnames && cfg.hostnames != [ ]) {
                  PASEO_HOSTNAMES = lib.concatStringsSep "," cfg.hostnames;
                }
                // lib.optionalAttrs (cfg.relay.enable && cfg.relay.endpoint != null) {
                  PASEO_RELAY_ENDPOINT = cfg.relay.endpoint;
                }
                // lib.optionalAttrs (cfg.relay.enable && cfg.relay.publicEndpoint != null) {
                  PASEO_RELAY_PUBLIC_ENDPOINT = cfg.relay.publicEndpoint;
                }
                // lib.optionalAttrs (cfg.relay.enable && cfg.relay.useTls) {
                  PASEO_RELAY_USE_TLS = "true";
                }
                // cfg.environment;
                StandardOutPath = "${cfg.dataDir}/logs/launchd-stdout.log";
                StandardErrorPath = "${cfg.dataDir}/logs/launchd-stderr.log";
                ProcessType = "Background";
              };
        };
      })
    ]
  );
}
