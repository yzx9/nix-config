{
  pkgs,
  ...
}:

{
  name = "signoz";

  nodes.machine =
    { pkgs, ... }:
    {
      imports = [ ../signoz.nix ];

      environment.systemPackages = [
        pkgs.curl
        pkgs.iproute2
      ];

      services.signoz = {
        enable = true;
        host = "127.0.0.1";
        port = 8080;
      };

      virtualisation = {
        memorySize = 4096;
        diskSize = 8192;
      };
    };

  testScript = ''
    import json


    def clickhouse_count(table):
        out = machine.succeed(
            "clickhouse client --query 'SELECT count() FROM " + table + "'"
        )
        return int(out.strip())


    machine.start()

    # No KVM in this environment: the VM runs under TCG emulation, so all
    # waits need generous explicit timeouts.
    machine.wait_for_unit("clickhouse-keeper.service", timeout=2400)
    machine.wait_for_unit("clickhouse.service", timeout=2400)
    machine.wait_for_unit("signoz-migrate.service", timeout=2400)
    machine.wait_for_unit("signoz.service", timeout=2400)
    machine.wait_for_unit("signoz-collector.service", timeout=2400)

    # Backend health and packaged web assets
    machine.wait_for_open_port(8080, timeout=1200)
    machine.succeed("curl -fsS http://127.0.0.1:8080/api/v1/health | grep -q 'ok'")
    index = machine.succeed("curl -fsS http://127.0.0.1:8080/")
    assert "html" in index, "web UI did not serve index.html"

    # The executable UDF helper must work from its immutable store path
    machine.succeed(
        "clickhouse client --query \"SELECT histogramQuantile([0.5, 1, 2, 4], [2, 3, 4, 4], 0.5)\""
    )

    # Ingest one OTLP trace with a current timestamp (stale spans are dropped)
    with subtest("otlp ingestion"):
        machine.wait_for_open_port(4318, timeout=1200)
        start = int(machine.succeed("date +%s%N").strip())
        payload = {
            "resourceSpans": [
                {
                    "resource": {
                        "attributes": [
                            {"key": "service.name", "value": {"stringValue": "nixos-test"}}
                        ]
                    },
                    "scopeSpans": [
                        {
                            "spans": [
                                {
                                    "traceId": "0123456789abcdef0123456789abcdef",
                                    "spanId": "0123456789abcdef",
                                    "name": "nixos-vm-span",
                                    "kind": 1,
                                    "startTimeUnixNano": str(start),
                                    "endTimeUnixNano": str(start + 1000000),
                                    "status": {},
                                }
                            ]
                        }
                    ],
                }
            ]
        }
        body = json.dumps(payload)
        machine.succeed(
            "curl -fsS -X POST http://127.0.0.1:4318/v1/traces"
            " -H 'content-type: application/json'"
            " --data-binary '" + body + "'"
        )

    with subtest("trace visible in telemetry store"):
        machine.wait_until_succeeds(
            "test \"$(clickhouse client --query 'SELECT count() FROM signoz_traces.distributed_signoz_spans')\" -ge 1",
            timeout=900,
        )

    with subtest("trace visible through service API"):
        machine.wait_until_succeeds(
            "curl -fsS 'http://127.0.0.1:8080/api/v1/services' | grep -q nixos-test",
            timeout=300,
        )

    with subtest("restart preserves state and secrets"):
        machine.succeed("test -s /var/lib/signoz/signoz.db")
        machine.succeed("test \"$(stat -c %a /var/lib/signoz/jwt-secret)\" = 600")
        machine.systemctl("stop signoz.service")
        machine.systemctl("start signoz.service")
        machine.wait_for_unit("signoz.service", timeout=1200)
        machine.succeed("test \"$(stat -c %a /var/lib/signoz/jwt-secret)\" = 600")
        assert clickhouse_count("signoz_traces.distributed_signoz_spans") >= 1

    with subtest("loopback-only listeners"):
        addrs = machine.succeed("ss -tln")
        assert "0.0.0.0:8080" not in addrs, "signoz bound publicly"
        assert "0.0.0.0:4317" not in addrs, "otlp grpc bound publicly"
        assert "0.0.0.0:4318" not in addrs, "otlp http bound publicly"
  '';
}
