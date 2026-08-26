#!/usr/bin/env bash
# Execute one backend operation with isolated output and a bounded duration.
set -euo pipefail

timeout_seconds="${1:-}"
backend="${2:-}"

runner_error() {
    local status="$1"
    shift
    printf '%d\0%s\n' "$status" "$*"
    exit 0
}

if [[ ! "$timeout_seconds" =~ ^[1-9][0-9]*$ ]]; then
    runner_error 2 'backend timeout must be a positive integer'
fi

if [[ -z "$backend" ]]; then
    runner_error 2 'backend path must not be empty'
fi

if (( $# < 3 )); then
    runner_error 2 'backend action must not be empty'
fi

for command in timeout mktemp cat rm; do
    if ! command -v "$command" >/dev/null 2>&1; then
        runner_error 127 "$command is required to execute Lunar Plasma backends"
    fi
done

shift 2

if ! temporary_directory="$(mktemp -d "${TMPDIR:-/tmp}/lunar-plasma-backend.XXXXXX")"; then
    runner_error 125 'could not create a temporary backend directory'
fi
stdout_path="$temporary_directory/stdout"
stderr_path="$temporary_directory/stderr"

cleanup() {
    rm -rf -- "$temporary_directory"
}

trap cleanup EXIT

set +e
timeout \
    --signal=TERM \
    --kill-after=1s \
    "${timeout_seconds}s" \
    "$backend" \
    "$@" \
    >"$stdout_path" \
    2>"$stderr_path"
status=$?
set -e

printf '%d\0' "$status"
if (( status == 0 )); then
    cat -- "$stdout_path"
elif [[ -s "$stderr_path" ]]; then
    cat -- "$stderr_path"
elif [[ -s "$stdout_path" ]]; then
    cat -- "$stdout_path"
fi

cleanup
trap - EXIT
exit 0
