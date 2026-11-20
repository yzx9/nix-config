# Offline GitHub API fixture: require the auth header on stdin, and only
# allow removal of the intended offline runner.
method=GET
while (($#)); do
  case "$1" in
    --request) method=$2; shift ;;
    --url) url=$2; shift ;;
    -H)
      [[ $2 != Authorization:* ]]
      shift
      ;;
  esac
  shift
done
IFS= read -r header
[[ $header == 'Authorization: Bearer '* ]]
route=${url#https://api.github.com/}
case "$method $route" in
  'GET app/installations?'*)
    [[ $header == 'Authorization: Bearer ey'* ]]
    printf '%s\n' '[{"account":{"login":"example"},"id":4}]'
    ;;
  'POST app/installations/4/access_tokens')
    printf '%s\n' '{"token":"app-installation"}'
    ;;
  'POST repos/example/project/actions/runners/registration-token')
    [[ $header == 'Authorization: Bearer app-installation' ]]
    printf '%s\n' '{"token":"app-registration"}'
    ;;
  'GET repos/example/project/actions/runners?'*)
    [[ $header == 'Authorization: Bearer app-installation' ]]
    printf '%s\n' '{"runners":[{"name":"app","status":"online","id":42},{"name":"other","status":"offline","id":99},{"name":"app","status":"offline","id":17}]}'
    ;;
  'DELETE repos/example/project/actions/runners/17')
    [[ $header == 'Authorization: Bearer app-installation' ]]
    printf 'delete\n' >> "$RUNNER_ROOT/api-calls"
    ;;
  *) printf 'Unexpected API request: %s %s\n' "$method" "$url" >&2; exit 1 ;;
esac
