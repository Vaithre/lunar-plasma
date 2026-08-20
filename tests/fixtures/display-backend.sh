#!/usr/bin/env bash
set -eu

case "${1:-}" in
    list-wallpapers)
        printf '1\torg.kde.image\tfile:///home/user/Pictures/one.png\n'
        printf '2\torg.kde.image\tfile:///home/user/Pictures/two.png\n'
        ;;
    get-wallpaper)
        case "${2:-}" in
            1) printf '1\torg.kde.image\tfile:///home/user/Pictures/one.png\n' ;;
            2) printf '2\torg.kde.image\tfile:///home/user/Pictures/two.png\n' ;;
            3) printf '3\torg.kde.image\t\n' ;;
            *) exit 1 ;;
        esac
        ;;
    set-wallpaper)
        [[ -n "${2:-}" ]]
        [[ "${3:-}" == "all" || "${3:-}" =~ ^[1-9][0-9]*$ ]]
        [[ -n "${4:-}" ]]
        ;;
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
