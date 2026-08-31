#!/usr/bin/env bash
set -eu

case "${1:-}" in
    screen-for-connector)
        case "${2:-}" in
            eDP-1) printf '1\n' ;;
            HDMI-A-1) printf '0\n' ;;
            *) exit 1 ;;
        esac
        ;;
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
        if [[ "${2:-}" == "/home/user/Pictures/connector.png" ]]; then
            [[ "${3:-}" == "1" ]]
        fi
        ;;
    *)
        exit 2
        ;;
esac
