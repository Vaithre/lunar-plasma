#!/usr/bin/env bash
set -eu

case "${1:-}" in
    get-status)
        printf 'true\tfalse\tfalse\tAA:BB:CC:DD:EE:FF\tLunar Adapter\n'
        ;;
    enable|disable|toggle)
        ;;
    list-devices)
        printf '11:22:33:44:55:66\ttrue\ttrue\ttrue\tfalse\tLunar Headphones\n'
        printf '77:88:99:AA:BB:CC\ttrue\tfalse\tfalse\tfalse\tLunar Controller\n'
        ;;
    list-connected-devices)
        printf '11:22:33:44:55:66\ttrue\ttrue\ttrue\tfalse\tLunar Headphones\n'
        ;;
    get-device)
        case "${2:-}" in
            11:22:33:44:55:66)
                printf '11:22:33:44:55:66\ttrue\ttrue\ttrue\tfalse\tLunar Headphones\n'
                ;;
            77:88:99:AA:BB:CC)
                printf '77:88:99:AA:BB:CC\ttrue\tfalse\tfalse\tfalse\tLunar Controller\n'
                ;;
            *)
                exit 1
                ;;
        esac
        ;;
    *)
        exit 2
        ;;
esac
