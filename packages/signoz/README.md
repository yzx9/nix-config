# SigNoz

Nix packaging for [SigNoz](https://signoz.io/) community edition plus a native
NixOS deployment. It replaces the unmerged `arize-phoenix` work with a
self-hosted observability service: OTLP traces, an APM-capable collector, and
the web UI.

## Build

```sh
nix build .#signoz                # backend + frontend + templates
nix build .#signoz-otel-collector # collector + schema migrator
```

`packages/signoz` produces:

- `bin/signoz` — community backend; resource directories are overridable via
  `SIGNOZ_WEB_DIRECTORY`, `SIGNOZ_EMAILING_TEMPLATES_DIRECTORY`, and
  `SIGNOZ_ALERTMANAGER_SIGNOZ_TEMPLATES`
- `share/signoz/web` — production frontend
- `share/signoz/templates` — email and alertmanager templates
- `libexec/signoz/histogramQuantile` — ClickHouse executable UDF helper used by
  histogram quantile queries

## NixOS module

```nix
services.signoz = {
  enable = true;
  host = "127.0.0.1";
  port = 31794;
};
```

The module brings up the full native stack on a single machine: SigNoz backend
(SQLite), SigNoz OTel collector, ClickHouse, ClickHouse Keeper, and a schema
migration oneshot. All listeners bind to loopback by default and nothing is
exposed through firewalls or proxies.

Environment precedence for the JWT secret:
`environmentFile` > `environment` > a runtime-generated secret persisted at
`/var/lib/signoz/jwt-secret` (created once, never rotated; setting an empty
value is an error).

State lives in:

- `/var/lib/signoz` — SQLite database and JWT secret
- `/var/lib/clickhouse` — telemetry store
- `/var/lib/clickhouse-keeper` — coordination log and snapshots

Send OTLP to `127.0.0.1:4317` (gRPC) or `127.0.0.1:4318` (HTTP) from the same
host, or forward those ports through your own tunnel if you need remote
ingestion. The upstream default trace TTL is 15 days; other tables differ.

## Verification

```sh
nix build .#checks.x86_64-linux.signoz --no-write-lock-file
```

runs a NixOS VM test covering migration on cold start, OTLP ingestion, query
visibility (including the `histogramQuantile` UDF), and restart persistence.
