#!/usr/bin/env bash
set -eu

case "${1:-}" in
    list-layouts)
        printf '1\tlatam\t\tSpanish (Latin American)\n'
        printf '2\tus\tintl\tEnglish (US, intl.)\n'
        ;;
    get-layout)
        printf '1\tlatam\t\tSpanish (Latin American)\n'
        ;;
    set-layout)
        [[ -n "${2:-}" ]] || exit 2
        (( 3 == $# )) || exit 2
        case "$2:$3" in
            us:intl|2:|latam:|1:) ;;
            *) exit 2 ;;
        esac
        ;;
    next-layout|previous-layout)
        ;;
    *)
        exit 2
        ;;
esac
