#!/usr/bin/env bash
# Read Plasma displays and change wallpapers through desktop services.
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

require_kscreen_doctor() {
    if ! command -v kscreen-doctor >/dev/null 2>&1; then
        printf 'kscreen-doctor is required to inspect Plasma displays\n' >&2
        return 127
    fi
}

kscreen_outputs() {
    NO_COLOR=1 kscreen-doctor --outputs |
        sed -E $'s/\x1B\[[0-9;]*[mK]//g'
}

list_displays() {
    require_kscreen_doctor

    kscreen_outputs | awk '
        function reset_output() {
            enabled = "false"
            connected = "false"
            priority = 0
            x = 0
            y = 0
            width = 0
            height = 0
            scale = 1
            rotation = 1
            mode_id = ""
            mode_width = ""
            mode_height = ""
            mode_refresh = ""
        }

        function read_modes(text, count, tokens, token_index, parts, flags) {
            count = split(text, tokens, /[[:space:]]+/)

            for (token_index = 1; token_index <= count; token_index += 1) {
                if (match(tokens[token_index], /^([0-9]+):([0-9]+)x([0-9]+)@([0-9.]+)([*!]*)$/, parts)) {
                    flags = parts[5]
                    if (flags ~ /\*/) {
                        mode_id = parts[1]
                        mode_width = parts[2]
                        mode_height = parts[3]
                        mode_refresh = parts[4]
                    }
                }
            }
        }

        function emit_output(primary) {
            if (!active) {
                return
            }

            primary = enabled == "true" && priority == 1 ? "true" : "false"
            printf "%d\t%s\t%s\t%s\t%s\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%d\t%s\t%s\t%s\t%s\n", \
                output_index, id, name, uuid, enabled, connected, primary, priority, \
                x, y, width, height, scale, rotation, mode_id, mode_width, mode_height, mode_refresh
        }

        /^Output:[[:space:]]+/ {
            emit_output()
            reset_output()
            active = 1
            output_index += 1
            id = $2
            name = $3
            uuid = $4
            next
        }

        {
            line = $0
            sub(/^[[:space:]]+/, "", line)

            if (line == "enabled") {
                enabled = "true"
            } else if (line == "connected") {
                connected = "true"
            } else if (match(line, /^priority ([0-9]+)$/, parts)) {
                priority = parts[1]
            } else if (match(line, /^Modes:[[:space:]]*(.*)$/, parts)) {
                read_modes(parts[1])
            } else if (match(line, /^Geometry:[[:space:]]*(-?[0-9]+),(-?[0-9]+) ([0-9]+)x([0-9]+)$/, parts)) {
                x = parts[1]
                y = parts[2]
                width = parts[3]
                height = parts[4]
            } else if (match(line, /^Scale:[[:space:]]*([0-9.]+)$/, parts)) {
                scale = parts[1]
            } else if (match(line, /^Rotation:[[:space:]]*([0-9]+)$/, parts)) {
                rotation = parts[1]
            }
        }

        END {
            emit_output()
        }
    '
}

list_display_modes() {
    local target="$1"

    require_kscreen_doctor

    kscreen_outputs | awk -v target="$target" '
        /^Output:[[:space:]]+/ {
            selected = $3 == target
            next
        }

        selected {
            line = $0
            sub(/^[[:space:]]+/, "", line)

            if (match(line, /^Modes:[[:space:]]*(.*)$/, values)) {
                count = split(values[1], tokens, /[[:space:]]+/)

                for (token_index = 1; token_index <= count; token_index += 1) {
                    if (match(tokens[token_index], /^([0-9]+):([0-9]+)x([0-9]+)@([0-9.]+)([*!]*)$/, parts)) {
                        preferred = parts[5] ~ /!/ ? "true" : "false"
                        current = parts[5] ~ /\*/ ? "true" : "false"
                        printf "%s\t%s\t%s\t%s\t%s\t%s\n", \
                            parts[1], parts[2], parts[3], parts[4], preferred, current
                    }
                }

                found = 1
                exit
            }
        }

        END {
            if (!found) {
                exit 1
            }
        }
    '
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
    list-displays)
        list_displays
        ;;
    list-display-modes)
        list_display_modes "${2:-}"
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
