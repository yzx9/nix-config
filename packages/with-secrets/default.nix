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
        touch "$out"
      '';

      # --map auto-adds TO env to allowlist
      mapAutoAllow = runCommand "with-secrets-test-map-auto-allow" { } ''
        set -euo pipefail
        echo 'keyX=valX' > secrets.env

        result="$(${with-secrets} secrets.env --map keyX ENVX -- ${sh} -c 'printf "%s" "$ENVX"')"
        [[ "$result" == "valX" ]]
        touch "$out"
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
          -- ${sh} -ec '
            [[ "$AAA" == "aaa" ]]
            [[ "$TO" == "fromval" ]]
            [[ ! -v BBB ]]
            [[ ! -v FROM ]]
            printf ok
          ')"

        [[ "$result" == "ok" ]]
        touch "$out"
      '';

      # multi-file override (later file wins)
      multiFileOverride = runCommand "with-secrets-test-multi-file-override" { } ''
        set -euo pipefail
        echo 'FOO=' > a.env
        echo 'FOO=two' > b.env

        result="$(${with-secrets} a.env b.env --allow FOO -- ${sh} -c 'printf "%s" "$FOO"')"
        [[ "$result" == "two" ]]
        touch "$out"
      '';

      failMissing = runCommand "with-secrets-test-fail-missing" { } ''
        set -euo pipefail
        echo 'FOO=ok' > secrets.env

        status=0
        MISSING=inherited ${with-secrets} secrets.env --allow MISSING -- touch ran 2>stderr || status=$?
        [[ "$status" == 1 && ! -e ran ]]
        grep -Fq "key 'MISSING' missing or empty" stderr
        touch "$out"
      '';

      failEmptyOverride = runCommand "with-secrets-test-fail-empty-override" { } ''
        set -euo pipefail
        echo 'SOURCE=ok' > a.env
        echo 'SOURCE=' > b.env

        status=0
        ${with-secrets} a.env b.env --map SOURCE DEST -- touch ran 2>stderr || status=$?
        [[ "$status" == 1 && ! -e ran ]]
        grep -Fq "key 'SOURCE' missing or empty for env 'DEST'" stderr
        touch "$out"
      '';

      warnMissing = runCommand "with-secrets-test-warn-missing" { } ''
        set -euo pipefail
        echo 'FOO=ok' > secrets.env

        result="$(MISSING=inherited ${with-secrets} secrets.env --no-fast-fail --allow MISSING --allow FOO -- \
          ${sh} -c 'printf "%s:%s" "$FOO" "$MISSING"' 2>stderr)"
        [[ "$result" == "ok:inherited" ]]
        grep -Fq "Warning: key 'MISSING' not found" stderr
        touch "$out"
      '';

      allowEmpty = runCommand "with-secrets-test-allow-empty" { } ''
        set -euo pipefail
        echo 'SOURCE=' > secrets.env

        DEST=inherited ${with-secrets} secrets.env --map SOURCE DEST --no-fast-fail -- \
          ${sh} -ec '[[ -v DEST && -z "$DEST" ]]'
        touch "$out"
      '';

      failUnreadableFile = runCommand "with-secrets-test-fail-unreadable-file" { } ''
        set -euo pipefail

        for options in "" --no-fast-fail; do
          args=()
          if [[ -n "$options" ]]; then args+=("$options"); fi
          status=0
          ${with-secrets} missing.env "''${args[@]}" -- touch ran 2>stderr || status=$?
          [[ "$status" == 2 && ! -e ran ]]
          grep -Fq 'cannot read: missing.env' stderr
        done
        touch "$out"
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
