#!/usr/bin/env bash
# Read and change wallpapers through the PlasmaShell D-Bus interface.
set -euo pipefail

action="${1:-}"

find_qdbus() {
    local candidate

    for candidate in qdbus-qt6 qdbus6 qdbus-qt5 qdbus; do
        if command -v "$candidate" >/dev/null 2>&1; then
            command -v "$candidate"
            return 0
        fi
    done

    return 1
}

wallpaper_state() {
    local qdbus="$1"
    local screen="$2"
    local output
    local plugin
    local uri

    output="$("$qdbus" --literal \
        org.kde.plasmashell \
        /PlasmaShell \
        org.kde.PlasmaShell.wallpaper \
        "$screen")"

    if [[ "$output" == *'a{sv} {}'* ]]; then
        return 1
    fi

    plugin="$(sed -n -E 's/.*"wallpaperPlugin" = \[Variant\(QString\): "([^"]*)"\].*/\1/p' <<<"$output")"
    uri="$(sed -n -E 's/.*"Image" = \[Variant\(QString\): "([^"]*)"\].*/\1/p' <<<"$output")"

    if [[ -z "$plugin" || -z "$uri" ]]; then
        printf 'could not read wallpaper state for display %d\n' "$((screen + 1))" >&2
        return 1
    fi

    printf '%d\t%s\t%s\n' "$((screen + 1))" "$plugin" "$uri"
}

list_wallpapers() {
    local qdbus
    local screen
    local found=0

    if ! qdbus="$(find_qdbus)"; then
        printf 'qdbus is required to read Plasma wallpapers\n' >&2
        return 127
    fi

    for ((screen = 0; screen < 64; screen += 1)); do
        if wallpaper_state "$qdbus" "$screen"; then
            found=1
        else
            break
        fi
    done

    if (( found == 0 )); then
        printf 'no Plasma displays are available\n' >&2
        return 1
    fi
}

get_wallpaper() {
    local display="$1"
    local qdbus

    if ! qdbus="$(find_qdbus)"; then
        printf 'qdbus is required to read Plasma wallpapers\n' >&2
        return 127
    fi

    if ! wallpaper_state "$qdbus" "$((display - 1))"; then
        printf 'display not found: %s\n' "$display" >&2
        return 1
    fi
}

normalize_uri() {
    local path="$1"
    local absolute

    if [[ "$path" == file://* ]]; then
        printf '%s\n' "$path"
        return
    fi

    if [[ ! -f "$path" ]]; then
        printf 'wallpaper file does not exist: %s\n' "$path" >&2
        return 1
    fi

    if command -v realpath >/dev/null 2>&1; then
        absolute="$(realpath -- "$path")"
    elif [[ "$path" == /* ]]; then
        absolute="$path"
    else
        absolute="$PWD/$path"
    fi

    printf 'file://%s\n' "$absolute"
}

set_wallpaper_for_screen() {
    local uri="$1"
    local plugin="$2"
    local screen="$3"
    local escaped_uri

    if command -v busctl >/dev/null 2>&1; then
        busctl --user call \
            org.kde.plasmashell \
            /PlasmaShell \
            org.kde.PlasmaShell \
            setWallpaper \
            'sa{sv}u' "$plugin" 1 Image s "$uri" "$screen" >/dev/null
        return
    fi

    if command -v gdbus >/dev/null 2>&1; then
        escaped_uri="${uri//\\/\\\\}"
        escaped_uri="${escaped_uri//\'/\\\'}"
        gdbus call --session \
            --dest org.kde.plasmashell \
            --object-path /PlasmaShell \
            --method org.kde.PlasmaShell.setWallpaper \
            "$plugin" "{'Image': <'$escaped_uri'>}" "$screen" >/dev/null
        return
    fi

    printf 'busctl or gdbus is required to change Plasma wallpapers\n' >&2
    return 127
}

set_wallpaper() {
    local path="$1"
    local target="$2"
    local plugin="$3"
    local uri
    local display
    local current_plugin
    local current_uri
    local wallpapers

    uri="$(normalize_uri "$path")"

    if [[ "$target" != "all" ]]; then
        set_wallpaper_for_screen "$uri" "$plugin" "$((target - 1))"
        return
    fi

    wallpapers="$(list_wallpapers)"

    while IFS=$'\t' read -r display current_plugin current_uri; do
        set_wallpaper_for_screen "$uri" "$plugin" "$((display - 1))"
    done <<<"$wallpapers"
}

case "$action" in
    list-wallpapers)
        list_wallpapers
        ;;
    get-wallpaper)
        get_wallpaper "${2:-}"
        ;;
    set-wallpaper)
        set_wallpaper "${2:-}" "${3:-all}" "${4:-org.kde.image}"
        ;;
    *)
        printf 'unknown desktop action: %s\n' "$action" >&2
        exit 2
        ;;
esac
