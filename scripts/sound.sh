#!/usr/bin/env bash
# Control the default output through PulseAudio's command interface.
set -euo pipefail

export LC_ALL=C

action="${1:-}"
value="${2:-}"

if ! command -v pactl >/dev/null 2>&1; then
    printf 'pactl is required to control the Plasma audio backend\n' >&2
    exit 127
fi

validate_percentage() {
    if [[ ! "$value" =~ ^[0-9]+$ ]] || (( value > 100 )); then
        printf 'value must be an integer between 0 and 100\n' >&2
        exit 2
    fi
}

case "$action" in
    set)
        validate_percentage
        pactl set-sink-volume '@DEFAULT_SINK@' "${value}%"
        ;;
    get)
        pactl get-sink-volume '@DEFAULT_SINK@' |
            awk 'match($0, /[0-9]+%/) { print substr($0, RSTART, RLENGTH - 1); exit }'
        ;;
    mute)
        pactl set-sink-mute '@DEFAULT_SINK@' 1
        ;;
    unmute)
        pactl set-sink-mute '@DEFAULT_SINK@' 0
        ;;
    is-muted)
        case "$(pactl get-sink-mute '@DEFAULT_SINK@')" in
            "Mute: yes") printf 'true\n' ;;
            "Mute: no") printf 'false\n' ;;
            *) printf 'could not read mute state\n' >&2; exit 1 ;;
        esac
        ;;
    toggle-mute)
        pactl set-sink-mute '@DEFAULT_SINK@' toggle
        ;;
    *)
        printf 'unknown sound action: %s\n' "$action" >&2
        exit 2
        ;;
esac
