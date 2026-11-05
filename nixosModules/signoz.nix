{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.signoz;

  collectorConfigFile = (pkgs.formats.yaml { }).generate "collector.yaml" {
    receivers = {
      otlp = {
        protocols = {
          grpc.endpoint = "${cfg.otlpHost}:${toString cfg.otlpGrpcPort}";
          http.endpoint = "${cfg.otlpHost}:${toString cfg.otlpHttpPort}";
        };
      };
    };

    processors = {
      batch = {
        send_batch_size = 10000;
        send_batch_max_size = 11000;
        timeout = "10s";
      };
      "signozspanmetrics/delta" = {
        metrics_exporter = "signozclickhousemetrics";
        metrics_flush_interval = "60s";
        latency_histogram_buckets = [
          "100us"
          "1ms"
          "2ms"
          "6ms"
          "10ms"
          "50ms"
          "100ms"
          "250ms"
          "500ms"
          "1000ms"
          "1400ms"
          "2000ms"
          "5s"
          "10s"
          "20s"
          "40s"
          "60s"
        ];
        dimensions_cache_size = 100000;
        aggregation_temporality = "AGGREGATION_TEMPORALITY_DELTA";
        enable_exp_histogram = true;
        dimensions = [
          {
            name = "service.namespace";
            default = "default";
          }
          {
            name = "deployment.environment";
            default = "default";
          }
          { name = "signoz.collector.id"; }
          { name = "service.version"; }
          { name = "browser.platform"; }
          { name = "browser.mobile"; }
          { name = "k8s.cluster.name"; }
          { name = "k8s.node.name"; }
          { name = "k8s.namespace.name"; }
          { name = "host.name"; }
          { name = "host.type"; }
          { name = "container.name"; }
        ];
      };
    };

    extensions = {
      health_check.endpoint = "127.0.0.1:13133";
    };

    exporters = {
      clickhousetraces = {
        datasource = "tcp://127.0.0.1:9000/signoz_traces";
        use_new_schema = true;
      };
      signozclickhousemetrics = {
        dsn = "tcp://127.0.0.1:9000/signoz_metrics";
      };
    };

    service = {
      telemetry.logs.encoding = "json";
      extensions = [ "health_check" ];
      pipelines = {
        traces = {
          receivers = [ "otlp" ];
          processors = [
            "signozspanmetrics/delta"
            "batch"
          ];
          exporters = [ "clickhousetraces" ];
        };
        metrics = {
          receivers = [ "otlp" ];
          processors = [ "batch" ];
          exporters = [ "signozclickhousemetrics" ];
        };
      };
    };
  };

  keeperConfig = pkgs.writeText "keeper.xml" ''
    <clickhouse>
        <logger>
            <level>information</level>
            <console>1</console>
        </logger>
        <listen_host>127.0.0.1</listen_host>
        <!-- Raft has a separate bind setting; listen_host only covers clients. -->
        <interserver_listen_host>127.0.0.1</interserver_listen_host>
        <keeper_server>
            <tcp_port>9181</tcp_port>
            <server_id>1</server_id>
            <log_storage_path>/var/lib/clickhouse-keeper/coordination/log</log_storage_path>
            <snapshot_storage_path>/var/lib/clickhouse-keeper/coordination/snapshots</snapshot_storage_path>
            <coordination_settings>
                <operation_timeout_ms>10000</operation_timeout_ms>
                <session_timeout_ms>30000</session_timeout_ms>
                <raft_logs_level>information</raft_logs_level>
            </coordination_settings>
            <raft_configuration>
                <server>
                    <id>1</id>
                    <hostname>127.0.0.1</hostname>
                    <port>9234</port>
                </server>
            </raft_configuration>
        </keeper_server>
    </clickhouse>
  '';

  clickhouseUdfConfig = pkgs.writeText "custom-function.xml" ''
    <functions>
        <function>
            <type>executable</type>
            <name>histogramQuantile</name>
            <format>CSV</format>
            <return_type>Float64</return_type>
            <argument>
                <name>buckets</name>
                <type>Array(Float64)</type>
            </argument>
            <argument>
                <name>counts</name>
                <type>Array(Float64)</type>
            </argument>
            <argument>
                <name>quantile</name>
                <type>Float64</type>
            </argument>
            <command>histogramQuantile</command>
            <execute_direct>1</execute_direct>
        </function>
    </functions>
  '';

  migrateScript = pkgs.writeShellScript "signoz-migrate" ''
    set -euo pipefail
    ${cfg.collectorPackage}/bin/signoz-otel-collector migrate ready
    ${cfg.collectorPackage}/bin/signoz-otel-collector migrate bootstrap
    ${cfg.collectorPackage}/bin/signoz-otel-collector migrate sync up
    ${cfg.collectorPackage}/bin/signoz-otel-collector migrate async up
    ${cfg.collectorPackage}/bin/signoz-otel-collector migrate sync check
  '';

  # JWT secret handling: systemd EnvironmentFile > module environment > a
  # runtime-generated secret persisted under /var/lib/signoz. The secret is
  # never written to the Nix store and an explicitly empty value is an error.
  startScript = pkgs.writeShellScript "signoz-start" ''
    set -euo pipefail
    secret_file=/var/lib/signoz/jwt-secret
    if [ "''${SIGNOZ_TOKENIZER_JWT_SECRET+x}" = x ] && [ -z "''${SIGNOZ_TOKENIZER_JWT_SECRET}" ]; then
      echo "SIGNOZ_TOKENIZER_JWT_SECRET is set but empty" >&2
      exit 1
    fi
    if [ -z "''${SIGNOZ_TOKENIZER_JWT_SECRET:-}" ]; then
      if [ ! -s "$secret_file" ]; then
        umask 077
        secret="$(head -c 64 /dev/urandom | base64)"
        printf '%s' "$secret" > "$secret_file.tmp"
        mv "$secret_file.tmp" "$secret_file"
      fi
      export SIGNOZ_TOKENIZER_JWT_SECRET="$(cat "$secret_file")"
    fi
    exec ${lib.getExe cfg.package} server
  '';

  commonHardening = {
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateTmp = true;
    PrivateDevices = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectControlGroups = true;
    RestrictNamespaces = true;
    LockPersonality = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    SystemCallArchitectures = "native";
    CapabilityBoundingSet = "";
    RestrictAddressFamilies = [
      "AF_UNIX"
      "AF_INET"
      "AF_INET6"
    ];
  };
in
{
  options.services.signoz = {
    enable = lib.mkEnableOption "SigNoz observability platform (community edition)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.yzx9.signoz;
      defaultText = "pkgs.yzx9.signoz";
      description = "SigNoz package to use";
    };

    collectorPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.yzx9.signoz-otel-collector;
      defaultText = "pkgs.yzx9.signoz-otel-collector";
      description = "SigNoz OpenTelemetry collector package to use";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address for the SigNoz API server and web UI to bind";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port for the SigNoz API server and web UI";
    };

    otlpHost = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address for the OTLP receiver to bind";
    };

    otlpGrpcPort = lib.mkOption {
      type = lib.types.port;
      default = 4317;
      description = "Port for the OTLP gRPC receiver";
    };

    otlpHttpPort = lib.mkOption {
      type = lib.types.port;
      default = 4318;
      description = "Port for the OTLP HTTP receiver";
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Extra environment variables (SIGNOZ_*) for the SigNoz backend service";
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Environment file passed to the SigNoz backend service, e.g. with
        SIGNOZ_TOKENIZER_JWT_SECRET. It takes precedence over
        {option}`services.signoz.environment` and the generated fallback JWT
        secret.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.clickhouse = {
      enable = true;

      # Single-node but complete replication topology: migrations run
      # ON CLUSTER, so the named cluster, macros and distributed DDL queue
      # are mandatory even on one machine.
      serverConfig = {
        listen_host = "127.0.0.1";
        http_port = 8123;
        tcp_port = 9000;
        distributed_ddl.path = "/clickhouse/task_queue/ddl";
        remote_servers = {
          cluster.shard.replica = [
            {
              host = "127.0.0.1";
              port = 9000;
            }
          ];
        };
        zookeeper.node = [
          {
            host = "127.0.0.1";
            port = 9181;
          }
        ];
        macros = {
          shard = "01";
          replica = "01";
        };
        user_scripts_path = "${cfg.package}/libexec/signoz";
        user_defined_executable_functions_config = "*function.xml";

        # SigNoz's schema (written for ClickHouse 25.12) intentionally keeps
        # dimension columns outside the sorting key of some
        # AggregatingMergeTree tables; ClickHouse 26.8 rejects that by
        # default. It is a table-level MergeTree setting, so change the
        # server-side default for newly created tables instead of patching
        # every upstream CREATE TABLE.
        merge_tree.allow_dimensions_outside_sorting_key = 1;
      };
    };

    environment.etc = {
      "clickhouse-server/custom-function.xml".source = clickhouseUdfConfig;
      "clickhouse-keeper/keeper.xml".source = keeperConfig;
      "signoz/collector.yaml".source = collectorConfigFile;
    };

    users.users = {
      signoz = {
        isSystemUser = true;
        group = "signoz";
        home = "/var/lib/signoz";
        createHome = false;
      };
      signoz-collector = {
        isSystemUser = true;
        group = "signoz-collector";
      };
      clickhouse-keeper = {
        isSystemUser = true;
        group = "clickhouse-keeper";
      };
    };
    users.groups = {
      signoz = { };
      signoz-collector = { };
      clickhouse-keeper = { };
    };

    systemd.services.clickhouse-keeper = {
      description = "ClickHouse Keeper for SigNoz";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        User = "clickhouse-keeper";
        Group = "clickhouse-keeper";
        StateDirectory = "clickhouse-keeper";
        StateDirectoryMode = "0750";
        ExecStart = "${config.services.clickhouse.package}/bin/clickhouse keeper --config-file=/etc/clickhouse-keeper/keeper.xml";
        # Keeper accepts client connections only after Raft initialization
        # completes, so a lightweight TCP connect probe is the readiness
        # gate. Do NOT use `keeper-client` here: spawning the full ClickHouse
        # binary per attempt exceeds any sane timeout under emulation.
        ExecStartPost = pkgs.writeShellScript "clickhouse-keeper-wait" ''
          for _ in $(seq 1 300); do
            if ${lib.getExe' pkgs.netcat "nc"} -z -w 1 127.0.0.1 9181 2>/dev/null; then
              exit 0
            fi
            sleep 1
          done
          echo "clickhouse-keeper did not become ready" >&2
          exit 1
        '';
        Restart = "on-failure";
      }
      // commonHardening;
    };

    systemd.services.clickhouse = {
      after = [ "clickhouse-keeper.service" ];
      wants = [ "clickhouse-keeper.service" ];
    };

    systemd.services.signoz-migrate = {
      description = "SigNoz ClickHouse schema migrations";
      after = [
        "clickhouse-keeper.service"
        "clickhouse.service"
      ];
      wants = [ "clickhouse-keeper.service" ];

      # Migrations are idempotent; retry across slow Keeper/ClickHouse
      # startup instead of leaving the stack wedged on one lost race.
      startLimitIntervalSec = 0;

      environment = {
        SIGNOZ_OTEL_COLLECTOR_CLICKHOUSE_DSN = "tcp://127.0.0.1:9000";
        SIGNOZ_OTEL_COLLECTOR_CLICKHOUSE_CLUSTER = "cluster";
        SIGNOZ_OTEL_COLLECTOR_CLICKHOUSE_REPLICATION = "true";
        SIGNOZ_OTEL_COLLECTOR_TIMEOUT = "10m";
      };

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "signoz";
        Group = "signoz";
        ExecStart = migrateScript;
        Restart = "on-failure";
        RestartSec = "5s";
      }
      // commonHardening;
    };

    systemd.services.signoz = {
      description = "SigNoz observability platform";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "signoz-migrate.service"
      ];
      requires = [ "signoz-migrate.service" ];

      environment = {
        SIGNOZ_APISERVER_ADDRESS = "${cfg.host}:${toString cfg.port}";
        SIGNOZ_SQLSTORE_PROVIDER = "sqlite";
        SIGNOZ_SQLSTORE_SQLITE_PATH = "/var/lib/signoz/signoz.db";
        # The upstream tracker is enabled with an empty default path. Keep
        # its queries.active file in the service's writable state directory.
        SIGNOZ_PROMETHEUS_ACTIVE__QUERY__TRACKER_PATH = "/var/lib/signoz/promql";
        SIGNOZ_TELEMETRYSTORE_PROVIDER = "clickhouse";
        SIGNOZ_TELEMETRYSTORE_CLICKHOUSE_DSN = "tcp://127.0.0.1:9000";
        SIGNOZ_TELEMETRYSTORE_CLICKHOUSE_CLUSTER = "cluster";
        SIGNOZ_ALERTMANAGER_PROVIDER = "signoz";
        # Keep the backend's self-instrumentation endpoint private.
        SIGNOZ_INSTRUMENTATION_METRICS_READERS_PULL_EXPORTER_PROMETHEUS_HOST = "127.0.0.1";
      }
      // cfg.environment;

      serviceConfig = {
        Type = "simple";
        User = "signoz";
        Group = "signoz";
        StateDirectory = "signoz";
        StateDirectoryMode = "0700";
        WorkingDirectory = "/var/lib/signoz";
        UMask = "0077";
        ExecStart = startScript;
        Restart = "on-failure";
      }
      // commonHardening
      // lib.optionalAttrs (cfg.environmentFile != null) {
        EnvironmentFile = cfg.environmentFile;
      };
    };

    systemd.services.signoz-collector = {
      description = "SigNoz OpenTelemetry collector";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "signoz-migrate.service"
      ];
      requires = [ "signoz-migrate.service" ];

      serviceConfig = {
        Type = "simple";
        User = "signoz-collector";
        Group = "signoz-collector";
        ExecStart = "${lib.getExe' cfg.collectorPackage "signoz-otel-collector"} --config=/etc/signoz/collector.yaml";
        Restart = "on-failure";
      }
      // commonHardening;
    };
  };
}
