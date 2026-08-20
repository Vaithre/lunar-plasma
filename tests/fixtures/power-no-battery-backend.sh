#!/usr/bin/env bash
set -eu

case "${1:-}" in
    get-profile)
        printf 'balanced\n'
        ;;
    get-battery-status)
        printf 'false\t\tunknown\tac\t\tnone\n'
        ;;
    *)
        exit 2
        ;;
esac
