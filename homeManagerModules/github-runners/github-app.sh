# Adapted from the NixOS github-runner app-token.sh, registration-token.sh,
# and remove-runner.sh (MIT; originally adapted from
# github.com/myoung34/docker-github-actions-runner, (c) 2020 Marcus Young).
# Supply auth headers via curl's stdin, not its arguments.
export PATH="$dependencies:$PATH"
IFS=/ read -r host owner repo <<<"${repo_url#https://}"
if [[ ${host,,} == github.com ]]; then
  api=https://api.github.com
else
  api="https://$host/api/v3"
fi
repo=${repo%/}
if [[ -z $repo ]]; then
  runners="orgs/$owner/actions/runners"
elif [[ $owner == enterprises ]]; then
  runners="enterprises/$repo/actions/runners"
else
  runners="repos/$owner/$repo/actions/runners"
fi

api_request() {
  # $auth is local to the caller. It never enters a child process's argv.
  printf 'Authorization: Bearer %s\n' "$auth" |
    curl --disable -fsS --connect-timeout 10 --max-time 60 --request "$1" -H @- \
      -H 'Accept: application/vnd.github+json' \
      -H 'Content-Length: 0' \
      --url "$api/$2"
}

base64url() {
  base64 | tr '+/' '-_' | tr -d '=\n'
}

app_access_token() {
  local key now jwt auth page installations id
  key=$(runtime_file "$key_file")
  now=$(date +%s)
  jwt=$(printf '{"alg":"RS256","typ":"JWT"}' | base64url)
  jwt+=.$(printf '{"iat":%d,"exp":%d,"iss":%d}' "$((now - 60))" "$((now + 540))" "$app_id" | base64url)
  auth="$jwt.$(printf '%s' "$jwt" | openssl dgst -binary -sha256 -sign "$key" | base64url)"
  page=1
  while true; do
    installations=$(api_request GET "app/installations?per_page=100&page=$page")
    id=$(jq -r --arg login "$app_login" '
      first(.[] | select((.account.login | ascii_downcase) == ($login | ascii_downcase)) | .id) // empty
    ' <<<"$installations")
    if [[ $id =~ ^[0-9]+$ ]]; then
      api_request POST "app/installations/$id/access_tokens" | jq -er '.token | strings | select(test("^[A-Za-z0-9_-]+$"))'
      return
    fi
    [[ $(jq length <<<"$installations") == 100 ]] || fail 'GitHub App installation not found.'
    ((page += 1))
  done
}

remove_offline() {
  local name=${runner_name:-} id listing page=1
  [[ -n $name ]] || name=$(uname -n)
  while true; do
    listing=$(api_request GET "$runners?per_page=100&page=$page") || return 1
    id=$(jq -r --arg name "$name" '
      first(.runners[] | select(.name == $name and .status == "offline") | .id) // empty
    ' <<<"$listing") || return 1
    if [[ $id =~ ^[0-9]+$ ]]; then
      api_request DELETE "$runners/$id" >/dev/null || return 1
      return 0
    fi
    [[ $(jq '.runners | length' <<<"$listing") == 100 ]] || return 0
    ((page += 1))
  done
}

remove_app_runner() {
  local auth
  auth=$(app_access_token)
  remove_offline
}

app_registration_token() {
  local auth token
  auth=$(app_access_token)
  token=$(api_request POST "$runners/registration-token" | jq -er '.token | strings | select(test("^[A-Za-z0-9_-]+$"))')
  remove_offline || printf 'Could not remove any stale offline registration.\n' >&2
  printf '%s\n' "$token"
}
