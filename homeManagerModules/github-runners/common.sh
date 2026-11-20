# Shared by the one-shot registration commands, never by the running listener.
set +x +a
shopt -s inherit_errexit
umask 077
export -n token auth

fail() {
  printf '%s: %s\n' "$RUNNER_ROOT" "$*" >&2
  exit 1
}

# The listener also reads options from its environment, case-insensitively.
while IFS= read -r -d '' entry; do
  input=${entry%%=*}
  if [[ ${input^^} == ACTIONS_RUNNER_INPUT_* && $input != *[!a-zA-Z0-9_]* ]]; then
    unset "$input"
  fi
done < <(env -0)

prepare_directories() {
  if [[ $explicit_work == 1 && $(realpath -m -- "$work") != "$work" ]]; then
    fail 'Explicit workDir must not contain symlinks.'
  fi
  mkdir -p -- "$HOME" "$work"
}

found=0
for file in "${credentials[@]}"; do
  path="$RUNNER_ROOT/$file"
  if [[ -e $path || -L $path ]]; then
    [[ -f $path && -s $path && ! -L $path ]] || fail "Invalid credential file: $path"
    ((found += 1))
  fi
done
