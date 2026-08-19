#!/usr/bin/env bash
set -eu

case "${1:-}" in
    set)
        [[ "${2:-}" =~ ^[0-9]+$ ]] || exit 2
        ;;
    get)
        printf '40\n'
        ;;
    mute|unmute|toggle-mute)
        ;;
    is-muted)
        printf 'false\n'
        ;;
    *)
        exit 2
        ;;
esac
