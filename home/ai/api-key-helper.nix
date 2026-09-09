# Builder for an `apiKeyHelper` script: prints a single API key from the
# trusted age secret file to stdout, for use as Claude Code's `apiKeyHelper`
# (home/ai/claude-code.nix) or wherever else a key must be resolved from the
# same file at runtime (e.g. hosts/yzx9-ws/cc-keepalive.nix, which points
# `file` at the system agenix copy instead of the user session's).
#
# Routing auth through `apiKeyHelper` (a settings-level credential) rather
# than an `ANTHROPIC_AUTH_TOKEN` shell var means the token no longer depends
# on env inheritance, which background / AgentView sessions drop since
# v2.1.174. Errors go to stderr; a missing file or empty key exits non-zero.
# Only the trusted age file is parsed, never an arbitrary project `.envrc`.
{
  pkgs,
  name,
  key,
  file,
}:

pkgs.writeShellApplication {
  inherit name;
  text = ''
    # NB: on Darwin agenix sets `.path` to `$(getconf DARWIN_USER_TEMP_DIR)/…`,
    # so this must stay double-quoted for the command substitution to expand.
    file="${file}"
    key="${key}"

    if [[ ! -r "$file" ]]; then
      echo "${name}: cannot read secret file: $file" >&2
      exit 1
    fi

    value=""
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
        "" | \#*) continue ;;
        export\ *) line="''${line#export }" ;;
      esac
      case "$line" in
        "$key="*) value="''${line#"$key="}" ;;
      esac
    done < "$file"

    if [[ -z "$value" ]]; then
      echo "${name}: key '$key' not found or empty in: $file" >&2
      exit 1
    fi

    printf '%s' "$value"
  '';
}
