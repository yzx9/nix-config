# Offline stand-in for the packaged listener.
test "$HOME" = "$RUNNER_ROOT/home"
test "${https_proxy:-}" = http://proxy.example.org:8080
test -r "$SSL_CERT_FILE"
test "$TEST_VALUE" = "use \$HOME \"/x%y\""
test -z "${AcTions_Runner_INPUT_ePHeMeRaL+x}"
test -z "${ACTIONS_RUNNER_INPUT_LOCAL+x}"

case "$1" in
  configure)
    test ! -e "$RUNNER_ROOT/.runner"
    shift
    test "$1" = --unattended
    test "$2" = --disableupdate
    case "${ACTIONS_RUNNER_INPUT_TOKEN:-}:${ACTIONS_RUNNER_INPUT_PAT:-}" in
      test-token: | app-registration: | :ghp_fixture | :github_pat_rotated) ;;
      wrong-token: | :ghp_invalid)
        printf 'attempted overwrite\n' > "$RUNNER_ROOT/.runner"
        exit 1
        ;;
      *) exit 2 ;;
    esac
    printf '%s\n' "$@" >> "$RUNNER_ROOT/configure-args"
    for file in .runner .credentials .credentials_rsaparams; do
      printf 'fixture\n' > "$RUNNER_ROOT/$file"
    done
    printf 'configure\n' >> "$RUNNER_ROOT/calls"
    ;;
  remove)
    test "$#" = 1
    test "$ACTIONS_RUNNER_INPUT_TOKEN" = test-token
    rm -- "$RUNNER_ROOT"/{.runner,.credentials,.credentials_rsaparams}
    printf 'remove\n' >> "$RUNNER_ROOT/calls"
    ;;
  *) exit 1 ;;
esac
