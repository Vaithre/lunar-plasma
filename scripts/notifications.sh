#!/usr/bin/env bash
# Send desktop notifications through the freedesktop.org notification service.
set -euo pipefail

action="${1:-}"
title="${2:-}"
text="${3:-}"
icon="${4:-}"
sound="${5:-}"
timeout="${6:--1}"
notification_type="${7:-info}"

if [[ "$action" != "send" ]]; then
    printf 'unknown notifications action: %s\n' "$action" >&2
    exit 2
fi

if ! command -v notify-send >/dev/null 2>&1; then
    printf 'notify-send is required to send desktop notifications\n' >&2
    exit 127
fi

case "$notification_type" in
    info)
        urgency="normal"
        default_icon="dialog-information"
        ;;
    warning)
        urgency="critical"
        default_icon="dialog-warning"
        ;;
    error)
        urgency="critical"
        default_icon="dialog-error"
        ;;
    success)
        urgency="normal"
        default_icon="dialog-ok"
        ;;
    *)
        printf 'invalid notification type: %s\n' "$notification_type" >&2
        exit 2
        ;;
esac

arguments=(--app-name="Lunar Plasma" --urgency="$urgency")
arguments+=(--icon="${icon:-$default_icon}")

if (( timeout >= 0 )); then
    arguments+=(--expire-time="$timeout")
fi

if [[ -n "$sound" ]]; then
    if [[ "$sound" == */* ]]; then
        arguments+=(--hint="string:sound-file:$sound")
    else
        arguments+=(--hint="string:sound-name:$sound")
    fi
fi

notify-send "${arguments[@]}" "$title" "$text"
