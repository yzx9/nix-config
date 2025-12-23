{
  lib,
  stdenv,
  runCommand,
  bash,
}:

stdenv.mkDerivation (finalAttrs: {
  name = "with-secrets";
  version = "1.0.0";

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 ${./with-secrets.sh} $out/bin/with-secrets

    runHook postInstall
  '';

  passthru.tests =
    let
      with-secrets = lib.getExe finalAttrs.finalPackage;
      sh = lib.getExe bash;
    in
    {
      # same-name export via --allow
      allowSameName = runCommand "with-secrets-test-allow-same-name" { } ''
        set -euo pipefail
        cat > secrets.env <<'EOF'
        # comment
        FOO=bar
        EOF

        result="$(${with-secrets} secrets.env --allow FOO -- ${sh} -c 'printf "%s" "$FOO"')"
        [[ "$result" == "bar" ]]
        touch "$out" 2>/dev/null || true
      '';

      # --map auto-adds TO env to allowlist
      mapAutoAllow = runCommand "with-secrets-test-map-auto-allow" { } ''
        set -euo pipefail
        echo 'keyX=valX' > secrets.env

        result="$(${with-secrets} secrets.env --map keyX ENVX -- ${sh} -c 'printf "%s" "$ENVX"')"
        [[ "$result" == "valX" ]]
        touch "$out" 2>/dev/null || true
      '';

      # --allow works with --map
      onlyWhitelist = runCommand "with-secrets-test-only-whitelist" { } ''
        set -euo pipefail
        cat > secrets.env <<'EOF'
        AAA=aaa
        BBB=bbb
        FROM=fromval
        EOF

        result="$(${with-secrets} secrets.env \
          --allow AAA \
          --map FROM TO \
          -- ${bash}/bin/bash -c '
            [[ "$AAA" == "aaa" ]]
            [[ "$TO" == "fromval" ]]
            [[ -z "$${BBB-}" ]]
            [[ -z "$${FROM-}" ]]
            printf ok
          ')"

        [[ "$result" == "ok" ]]
        touch "$out" 2>/dev/null || true
      '';

      # multi-file override (later file wins)
      multiFileOverride = runCommand "with-secrets-test-multi-file-override" { } ''
        set -euo pipefail
        echo 'FOO=one' > a.env
        echo 'FOO=two' > b.env

        out="$(${with-secrets} a.env b.env --allow FOO -- ${sh} -c 'printf "%s" "$FOO"')"
        [[ "$out" == "two" ]]
        touch "$out" 2>/dev/null || true
      '';

      # missing key warns but command still runs
      warnMissing = runCommand "with-secrets-test-warn-missing" { } ''
        set -euo pipefail
        echo 'FOO=ok' > secrets.env

        stderr="$(mktemp)"
        result="$(${with-secrets} secrets.env --allow DOES_NOT_EXIST --allow FOO -- \
          ${bash}/bin/bash -c 'printf "%s" "$FOO"' 2>"$stderr")"
        [[ "$result" == "ok" ]]
        grep -q "Warning: key 'DOES_NOT_EXIST' not found" "$stderr"
        touch "$out" 2>/dev/null || true
      '';
    };

  meta = {
    description = "Utility to run commands with secrets injected as environment variables";
    license = lib.licenses.asl20;
    platforms = bash.meta.platforms;
    maintainers = with lib.maintainers; [
      yzx9
    ];
    mainProgram = "with-secrets";
  };
})
