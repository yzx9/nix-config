# Adapted from the token/reconfiguration lifecycle in NixOS's github-runner
# service.nix. Workspaces are never recursively deleted and only a digest of
# the registration settings and token is kept. Restore local identity files
# if a new registration fails (remote changes cannot be rolled back here).
runtime_file() {
  local path
  path=$(realpath -e -- "$1") || fail 'Credential file is unavailable.'
  [[ $path != "$store_dir/"* && -f $path && -r $path ]] ||
    fail 'Credentials must be readable files outside the Nix store.'
  printf '%s\n' "$path"
}

if [[ $1 == remove ]]; then
  if ((found == ${#credentials[@]})); then
    remove_app_runner
  fi
  exit 0
fi

# Explicit short-lived tokens bootstrap persistent runners once. Check the
# local identity before opening the file; replicas share it during enrollment.
if [[ -n $token_file && $token_type == registration && $ephemeral == 0 ]] &&
  ((found == ${#credentials[@]})); then
  exit 0
fi

prepare_directories
args=("${configure_args[@]}" --work "$work")
fingerprint=
stamp="$RUNNER_ROOT/.registration-digest"
if [[ -n $token_file ]]; then
  path=$(runtime_file "$token_file")
  token=$(<"$path")
  [[ -n $token && $token != *[[:space:]]* ]] || fail 'Token file must contain a single nonempty token.'
  input=TOKEN
  if [[ $token_type == access || ( $token_type == auto && $token =~ ^(gh[a-z]+_|github_pat_) ) ]]; then
    input=PAT
  fi
  if [[ $ephemeral == 0 && $token_type != registration ]]; then
    fingerprint=$(printf '%s\0' "$token" "$input" "${args[@]}" | sha256sum)
    if [[ $found == "${#credentials[@]}" && -f $stamp && $(<"$stamp") == "$fingerprint" ]]; then
      exit 0
    fi
  fi
else
  input=TOKEN
  token=$(app_registration_token)
fi

backup=$(mktemp -d -- "$RUNNER_ROOT/.registration.XXXXXX")
for file in "${credentials[@]}"; do
  if [[ -f $RUNNER_ROOT/$file ]]; then
    cp -- "$RUNNER_ROOT/$file" "$backup/$file"
  fi
done
rollback() {
  for file in "${credentials[@]}"; do
    if [[ -f $backup/$file ]]; then
      mv -fT -- "$backup/$file" "$RUNNER_ROOT/$file"
    else
      rm -f -- "$RUNNER_ROOT/$file"
    fi
  done
  rmdir -- "$backup"
}
trap rollback EXIT
trap 'exit 1' INT TERM
for file in "${credentials[@]}"; do
  rm -f -- "$RUNNER_ROOT/$file"
done
if [[ $input == PAT ]]; then
  ACTIONS_RUNNER_INPUT_PAT="$token" "$listener" "${args[@]}"
else
  ACTIONS_RUNNER_INPUT_TOKEN="$token" "$listener" "${args[@]}"
fi
unset token
for file in "${credentials[@]}"; do
  [[ -s $RUNNER_ROOT/$file ]] || fail 'Listener did not write a complete registration.'
done
if [[ -n $fingerprint ]]; then
  printf '%s\n' "$fingerprint" > "$backup/digest"
  mv -fT -- "$backup/digest" "$stamp"
else
  rm -f -- "$RUNNER_ROOT/.registration-digest"
fi
trap - EXIT INT TERM
for file in "${credentials[@]}"; do
  rm -f -- "$backup/$file"
done
rmdir -- "$backup"
