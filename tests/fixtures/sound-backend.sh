#!/usr/bin/env bash
set -eu

case "${1:-}" in
    set)
        [[ "${2:-}" =~ ^[0-9]+$ ]] || exit 2
        (( 2 == $# && $2 <= 100 )) || exit 2
        ;;
    get)
        (( 1 == $# )) || exit 2
        printf '40\n'
        ;;
    mute|unmute|toggle-mute)
        (( 1 == $# )) || exit 2
        ;;
    is-muted)
        (( 1 == $# )) || exit 2
        printf 'false\n'
        ;;
    *)
        exit 2
        ;;
esac
