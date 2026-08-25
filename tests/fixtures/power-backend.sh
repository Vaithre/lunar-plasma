#!/usr/bin/env bash
set -eu

case "${1:-}" in
    set-profile)
        case "${2:-}" in
            power-saver|balanced|performance) ;;
            *) exit 2 ;;
        esac
        ;;
    get-profile)
        printf 'balanced\n'
        ;;
    get-battery-status)
        printf 'true\t73.4\tdischarging\tbattery\t7200\tlow\n'
        ;;
    suspend|shutdown|reboot)
        ;;
    set-brightness)
        [[ -n "${2:-}" ]] || exit 2
        [[ "${3:-}" =~ ^[0-9]+$ ]] || exit 2
        (( 3 == $# && $3 <= 100 )) || exit 2
        ;;
    get-brightness)
        [[ -n "${2:-}" ]] || exit 2
        printf '40\n'
        ;;
    *)
        exit 2
        ;;
esac
