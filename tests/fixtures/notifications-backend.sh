#!/usr/bin/env bash
set -eu

[[ "${1:-}" == "send" ]] || exit 2
[[ -n "${2:-}" ]] || exit 2
[[ -n "${3:-}" ]] || exit 2
[[ "${6:-}" =~ ^-?[0-9]+$ ]] || exit 2

case "${7:-}" in
    info|warning|error|success) ;;
    *) exit 2 ;;
esac
