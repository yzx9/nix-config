#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: with-secrets FILE... [--no-fast-fail] [--allow ENV]... [--map FROM TO]... -- command [args...]" >&2
  echo "  --no-fast-fail  Warn on missing keys and allow empty values instead of failing." >&2
  exit 2
}

[[ $# -ge 1 ]] || usage

declare -a files=()
declare -A secrets=()
declare -A allow=()
declare -A map=()
fast_fail=true

# Collect FILE... until we hit an option or "--"
while [[ $# -gt 0 ]]; do
  case "$1" in
  --no-fast-fail | --allow | --map | --)
    break
    ;;
  *)
    files+=("$1")
    shift
    ;;
  esac
done

[[ ${#files[@]} -ge 1 ]] || usage

# Parse options until "--"
while [[ $# -gt 0 ]]; do
  case "$1" in
  --)
    shift
    break
    ;;
  --no-fast-fail)
    fast_fail=false
    shift
    ;;
  --allow)
    [[ -n "${2-}" ]] || {
      echo "with-secrets: --allow ENV required" >&2
      exit 2
    }
    allow["$2"]=1
    shift 2
    ;;
  --map)
    from="${2-}"
    to="${3-}"
    [[ -n "$from" && -n "$to" ]] || {
      echo "with-secrets: --map FROM TO required" >&2
      exit 2
    }
    map["$to"]="$from"
    allow["$to"]=1
    shift 3
    ;;
  *)
    echo "with-secrets: unknown arg: $1" >&2
    usage
    ;;
  esac
done

[[ $# -ge 1 ]] || {
  echo "with-secrets: missing command after --" >&2
  usage
}

for file in "${files[@]}"; do
  [[ -r "$file" ]] || {
    echo "with-secrets: cannot read: $file" >&2
    exit 2
  }
  while IFS='=' read -r key value; do
    [[ -z "$key" ]] && continue
    [[ "$key" == \#* ]] && continue
    secrets["$key"]="$value"
  done <"$file"
done

for env in "${!allow[@]}"; do
  key="${map[$env]:-$env}"
  if [[ "$fast_fail" == true && -z "${secrets[$key]-}" ]]; then
    echo "with-secrets: key '$key' missing or empty for env '$env'." >&2
    exit 1
  fi
  if [[ -v secrets["$key"] ]]; then
    export "$env=${secrets[$key]}"
  else
    echo "Warning: key '$key' not found for env '$env'." >&2
  fi
done

exec "$@"
