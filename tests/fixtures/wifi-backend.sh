#!/usr/bin/env bash
set -eu

case "${1:-}" in
    get-status)
        printf 'true\ttrue\tLunar Network\n'
        ;;
    enable|disable|toggle)
        ;;
    *)
        exit 2
        ;;
esac
