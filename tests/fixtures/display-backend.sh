#!/usr/bin/env bash
set -eu

case "${1:-}" in
    list-displays)
        printf '1\t1\teDP-1\tpanel-uuid\ttrue\ttrue\ttrue\t1\t0\t0\t1920\t1080\t1\t1\t2\t1920\t1080\t60\n'
        printf '2\t2\tHDMI-A-1\thdmi-uuid\tfalse\ttrue\tfalse\t0\t1920\t0\t2560\t1440\t1.25\t1\t\t\t\t\n'
        ;;
    list-display-modes)
        case "${2:-}" in
            eDP-1)
                printf '1\t1920\t1080\t60\ttrue\tfalse\n'
                printf '2\t1920\t1080\t60\tfalse\ttrue\n'
                ;;
            HDMI-A-1)
                printf '3\t2560\t1440\t144\ttrue\tfalse\n'
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
