#!/usr/bin/env bash
# Read and change Plasma wallpapers through desktop services.
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

javascript_string() {
    local value="$1"

    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    value="${value//$'\n'/\\n}"
    value="${value//$'\r'/\\r}"
    printf '"%s"' "$value"
}

screen_for_connector() {
    local connector="$1"
    local qdbus
    local quoted_connector
    local script
    local screen

    if [[ -z "$connector" ]]; then
        printf 'display connector must not be empty\n' >&2
        return 1
    fi

    if ! qdbus="$(find_qdbus)"; then
        printf 'qdbus is required to map display connectors to Plasma screens\n' >&2
        return 127
    fi

    quoted_connector="$(javascript_string "$connector")"
    script="print(screenForConnector($quoted_connector));"
    screen="$("$qdbus" \
        org.kde.plasmashell \
        /PlasmaShell \
        org.kde.PlasmaShell.evaluateScript \
        "$script")"

    if [[ ! "$screen" =~ ^-?[0-9]+$ ]]; then
        printf 'Plasma returned an invalid screen for connector %s\n' "$connector" >&2
        return 1
    fi

    if (( screen < 0 )); then
        printf 'display not found: %s\n' "$connector" >&2
        return 1
    fi

    printf '%d\n' "$screen"
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

    if [[ -z "$plugin" ]]; then
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
    local busctl_error=""
    local gdbus_error=""

    if command -v busctl >/dev/null 2>&1; then
        if busctl_error="$(busctl --user call \
            org.kde.plasmashell \
            /PlasmaShell \
            org.kde.PlasmaShell \
            setWallpaper \
            'sa{sv}u' "$plugin" 1 Image s "$uri" "$screen" 2>&1)"; then
            return
        fi
    fi

    if command -v gdbus >/dev/null 2>&1; then
        escaped_uri="${uri//\\/\\\\}"
        escaped_uri="${escaped_uri//\'/\\\'}"
        if gdbus_error="$(gdbus call --session \
            --dest org.kde.plasmashell \
            --object-path /PlasmaShell \
            --method org.kde.PlasmaShell.setWallpaper \
            "$plugin" "{'Image': <'$escaped_uri'>}" "$screen" 2>&1)"; then
            return
        fi
    fi

    printf 'Plasma rejected the wallpaper change through the available D-Bus clients\n' >&2
    if [[ -n "$busctl_error" ]]; then
        printf 'busctl: %s\n' "$busctl_error" >&2
    fi
    if [[ -n "$gdbus_error" ]]; then
        printf 'gdbus: %s\n' "$gdbus_error" >&2
    fi
    return 1
}

set_wallpaper() {
    local path="$1"
    local target="$2"
    local plugin="$3"
    local uri
    local display
    local wallpapers

    uri="$(normalize_uri "$path")"

    if [[ "$target" != "all" ]]; then
        set_wallpaper_for_screen "$uri" "$plugin" "$((target - 1))"
        return
    fi

    wallpapers="$(list_wallpapers)"

    while IFS=$'\t' read -r display _ _; do
        set_wallpaper_for_screen "$uri" "$plugin" "$((display - 1))"
    done <<<"$wallpapers"
}

case "$action" in
    screen-for-connector)
        screen_for_connector "${2:-}"
        ;;
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
