{ ... }:

{
  name = "signoz";

  nodes.machine =
    { pkgs, ... }:
    {
      imports = [ ../signoz.nix ];

      environment.systemPackages = [
        pkgs.curl
        pkgs.iproute2
        pkgs.jq
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
    import shlex
    from datetime import timedelta

    trace_id = "0123456789abcdef0123456789abcdef"
    span_id = "0123456789abcdef"
    span_query = (
        "SELECT count() FROM signoz_traces.distributed_signoz_index_v3 "
        f"WHERE trace_id = '{trace_id}' AND span_id = '{span_id}' "
        "AND name = 'nixos-vm-span'"
    )

    def api_post(path, body):
        command = shlex.join([
            "curl", "-fsS", "--max-time", "60", "-X", "POST",
            "http://127.0.0.1:8080" + path,
            "-H", "content-type: application/json",
            "--data-binary", json.dumps(body),
        ])
        return json.loads(machine.succeed(command))

    def assert_trace_visible(token):
        command = shlex.join([
            "curl", "-fsS", "--max-time", "60",
            f"http://127.0.0.1:8080/api/v1/traces/{trace_id}/summary",
            "-H", "Authorization: Bearer " + token,
            "-o", "/run/signoz-summary.json",
        ])
        # Retry the actual API result, not just its HTTP status. Distributed
        # writes of span/resource/summary data may become visible separately.
        predicate = (
            '.data.rootServiceName == "nixos-test" and '
            '.data.rootServiceEntryPoint == "nixos-vm-span" and '
            '.data.totalSpansCount == 1 and .data.hasMissingSpans == false'
        )
        machine.wait_until_succeeds(
            command + " && jq -e " + shlex.quote(predicate) + " /run/signoz-summary.json",
            timeout=timedelta(minutes=5),
        )

    machine.start()
    # Allow slower runners without KVM, but do not substitute longer waits
    # for assertions about migration success or actual ingested data.
    for unit in ["clickhouse-keeper", "clickhouse", "signoz-migrate", "signoz", "signoz-collector"]:
        machine.wait_for_unit(unit + ".service", timeout=timedelta(minutes=40))

    with subtest("backend and packaged frontend"):
        machine.wait_for_open_port(8080, timeout=timedelta(minutes=20))
        health = json.loads(machine.succeed("curl -fsS http://127.0.0.1:8080/api/v1/health"))
        assert health["status"] == "ok", health
        index = machine.succeed("curl -fsS http://127.0.0.1:8080/")
        assert "html" in index, "web UI did not serve index.html"

    with subtest("writable PromQL query tracker"):
        machine.succeed("test -s /var/lib/signoz/promql/queries.active")

    with subtest("executable histogram UDF"):
        query = "SELECT histogramQuantile([0.5, 1., 2., toFloat64('inf')], [2., 3., 4., 4.], 0.5)"
        quantile = machine.succeed(shlex.join(["clickhouse", "client", "--query", query]))
        assert float(quantile.strip()) == 0.5, quantile

    with subtest("real user registration and login"):
        email = "admin@nixos.test"
        password = "password123Z$"
        api_post("/api/v1/register", {
            "name": "NixOS test", "email": email, "password": password, "orgName": "",
        })
        context = json.loads(machine.succeed(shlex.join([
            "curl", "-fsS", "--get", "http://127.0.0.1:8080/api/v2/sessions/context",
            "--data-urlencode", "email=" + email,
            "--data-urlencode", "ref=http://127.0.0.1:8080",
        ])))
        org_id = context["data"]["orgs"][0]["id"]
        session = api_post("/api/v2/sessions/email_password", {
            "email": email, "password": password, "orgId": org_id,
        })
        token = session["data"]["accessToken"]
        assert token

    with subtest("OTLP ingestion"):
        machine.wait_for_open_port(4318, timeout=timedelta(minutes=20))
        start = int(machine.succeed("date +%s%N").strip())
        payload = {
            "resourceSpans": [{
                "resource": {"attributes": [
                    {"key": "service.name", "value": {"stringValue": "nixos-test"}},
                ]},
                "scopeSpans": [{"spans": [{
                    "traceId": trace_id, "spanId": span_id, "name": "nixos-vm-span",
                    "kind": 2, "startTimeUnixNano": str(start),
                    "endTimeUnixNano": str(start + 1000000), "status": {},
                }]}],
            }],
        }
        response = json.loads(machine.succeed(shlex.join([
            "curl", "-fsS", "-X", "POST", "http://127.0.0.1:4318/v1/traces",
            "-H", "content-type: application/json", "--data-binary", json.dumps(payload),
        ])))
        assert int(response.get("partialSuccess", {}).get("rejectedSpans", 0)) == 0, response

    with subtest("exact trace in V3 telemetry storage"):
        try:
            machine.wait_until_succeeds(
                "test \"$(" + shlex.join(["clickhouse", "client", "--query", span_query]) + ")\" = 1",
                timeout=timedelta(minutes=15),
            )
        except Exception:
            print(machine.succeed("clickhouse client --query 'SHOW TABLES FROM signoz_traces'"))
            print(machine.succeed("journalctl -u signoz-collector -n 80 --no-pager"))
            raise

    with subtest("authenticated API trace visibility"):
        assert_trace_visible(token)

    with subtest("restart preserves telemetry, account and JWT"):
        machine.succeed("test -s /var/lib/signoz/signoz.db")
        machine.succeed("test \"$(stat -c %a /var/lib/signoz/jwt-secret)\" = 600")
        jwt_before = machine.succeed("sha256sum /var/lib/signoz/jwt-secret")
        machine.systemctl("stop signoz.service signoz-collector.service")
        machine.systemctl("restart clickhouse.service")
        machine.wait_for_unit("clickhouse.service", timeout=timedelta(minutes=20))
        machine.systemctl("restart signoz-migrate.service")
        machine.systemctl("start signoz.service signoz-collector.service")
        machine.wait_for_unit("signoz.service", timeout=timedelta(minutes=20))
        assert machine.succeed("sha256sum /var/lib/signoz/jwt-secret") == jwt_before
        count = machine.succeed(shlex.join(["clickhouse", "client", "--query", span_query]))
        assert int(count.strip()) == 1, count
        # The pre-restart token must still authenticate after SQLite/JWT reload.
        assert_trace_visible(token)

    with subtest("loopback-only listeners"):
        listeners = machine.succeed("ss -H -ltn")
        private_ports = {8080, 4317, 4318, 8123, 9000, 9181, 9234, 9090, 13133}
        for line in listeners.splitlines():
            address, port = line.split()[3].rsplit(":", 1)
            if int(port) in private_ports:
                assert address in {"127.0.0.1", "[::1]"}, line
  '';
}
