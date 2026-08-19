#!/usr/bin/env bash
set -eu

case "${1:-}" in
    set-profile)
        case "${2:-}" in
            power-saver|balanced|performance) ;;
            *) exit 2 ;;
        esac
        ;;
    suspend|shutdown|reboot)
        ;;
    set-brightness)
        [[ -n "${2:-}" ]] || exit 2
        [[ "${3:-}" =~ ^[0-9]+$ ]] || exit 2
        ;;
    get-brightness)
        [[ -n "${2:-}" ]] || exit 2
        printf '40\n'
        ;;
    *)
        exit 2
        ;;
esac
