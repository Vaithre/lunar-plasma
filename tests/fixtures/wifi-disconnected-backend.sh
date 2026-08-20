#!/usr/bin/env bash
set -eu

case "${1:-}" in
    get-status)
        printf 'false\tfalse\t\n'
        ;;
    enable|disable|toggle)
        ;;
    *)
        exit 2
        ;;
esac
