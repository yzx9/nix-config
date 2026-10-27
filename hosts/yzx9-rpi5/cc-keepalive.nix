# System-level CC keepalive — survives Hermes gateway crashes.
#
# Background: the Claude Code quota keepalive used to run as Hermes cron jobs,
# i.e. inside the hermes-agent gateway process. When the kernel OOM killer took
# down the user systemd manager (user@1000.service), the gateway died and NO
# cron fired until someone manually restarted it. This module moves keepalive
# to a PID-1-managed systemd timer so it keeps running even if the whole user
# session crashes.
#
# Everything except the secret itself is wired at eval time: endpoint, model
# and key name are inlined below. The user `claude` wrapper on the daily
# machines goes through the local claude-code-proxy, which this machine does
# not run — the keepalive must stay direct-to-GLM. No runtime probing of
# store paths.
{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Direct-to-GLM constants, independent of the (proxy-based) home/ai stack.
  baseUrl = "https://open.bigmodel.cn/api/anthropic";
  # The cheap flash model keeps the quota warm at minimum cost. `[1m]` would
  # be a Claude Code alias suffix for 1M context, not part of the API model
  # id — use the bare model here.
  model = "glm-5.3-flash";

  # Key is resolved at process start from the *system* agenix copy: the
  # user-level `${XDG_RUNTIME_DIR}/agenix` path lives on the user session's
  # tmpfs and vanishes together with it — exactly what this keepalive must
  # survive. NB: agenix `.path` is runtime-expanded, keep it double-quoted.
  keyFile = config.age.secrets."llm-api-keys".path;

  # Inner script: expects GLM_CODING_API_KEY in the environment.
  ping = pkgs.writeShellApplication {
    name = "cc-keepalive-ping";
    runtimeInputs = [
      pkgs.curl
      pkgs.coreutils # mktemp, head
    ];
    text = ''
      body=$(mktemp)
      trap 'rm -f "$body"' EXIT
      code=$(curl -sS --connect-timeout 10 --max-time 60 -o "$body" -w '%{http_code}' \
        "${baseUrl}/v1/messages" \
        -H "x-api-key: $GLM_CODING_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d '{"model":"${model}","max_tokens":5,"messages":[{"role":"user","content":"ok"}]}')

      case "$code" in
        200) echo "cc-keepalive: ping ok (${model})" ;;
        429)
          # Rate-limited (bigmodel.cn code 1302): the account is already under
          # the rate-limit window — expected, self-healing, NOT a failure.
          ;;
        *)
          echo "⚠️ CC keepalive failed (HTTP $code): $(head -c 200 "$body")" >&2
          exit 1
          ;;
      esac
    '';
  };
in
{
  # Decrypted at boot by the system agenix unit from the host SSH key, so it
  # exists even with no user session. Same age file the user session
  # decrypts for the claude wrapper; owned by the service user because the
  # default root:0400 would be unreadable to it.
  age.secrets."llm-api-keys" = {
    file = ../../secrets/llm-api-keys.age;
    owner = "yzx9";
  };

  systemd.services.cc-keepalive = {
    description = "Claude Code quota keepalive (GLM API ping)";
    serviceConfig = {
      Type = "oneshot";
      # Runs as the quota owner, not root — the key file is chowned accordingly.
      User = "yzx9";
      # with-secrets only *warns* on a missing key; fail fast instead so the
      # journal shows the real problem instead of an empty-key 401.
      ExecStart = lib.getExe (
        pkgs.writeShellApplication {
          name = "cc-keepalive";
          runtimeInputs = [ pkgs.yzx9.with-secrets ];
          text = ''
            if ! grep -Eq '^(export )?GLM_CODING_API_KEY=.' "${keyFile}"; then
              echo "cc-keepalive: GLM_CODING_API_KEY missing or empty in ${keyFile}" >&2
              exit 1
            fi
            exec with-secrets "${keyFile}" \
              --allow GLM_CODING_API_KEY \
              -- ${lib.getExe ping}
          '';
        }
      );
      # Protect the keepalive itself from being first OOM victim.
      OOMScoreAdjust = "-500";
      # Sandboxing: needs nothing but network, the age secret and a private tmp.
      NoNewPrivileges = true;
      PrivateTmp = true;
    };
  };

  systemd.timers.cc-keepalive = {
    description = "Claude Code quota keepalive timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = [
        # Morning slots: early quota window often misses. Added more catch-up
        # pings so the 5h quota is refreshed before the workday.
        "*-*-* 05:35:00"
        "*-*-* 05:55:00"
        "*-*-* 06:15:00"
        "*-*-* 06:35:00"
        "*-*-* 06:55:00"
        "*-*-* 07:05:00"
        "*-*-* 10:37:00"
        "*-*-* 15:40:00"
        "*-*-* 20:43:00"
      ];
      # If the machine was off / the timer missed a slot, run once on boot.
      Persistent = true;
      RandomizedDelaySec = 0;
      Unit = "cc-keepalive.service";
    };
  };
}
