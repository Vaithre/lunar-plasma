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

        function read_modes(text, count, tokens, token_index, token, flags, values, dimensions) {
            count = split(text, tokens, /[[:space:]]+/)

            for (token_index = 1; token_index <= count; token_index += 1) {
                token = tokens[token_index]

                if (token ~ /^[0-9]+:[0-9]+x[0-9]+@[0-9.]+[*!]*$/) {
                    flags = token
                    sub(/^[^*!]*/, "", flags)
                    sub(/[*!]*$/, "", token)
                    split(token, values, /[:@]/)
                    split(values[2], dimensions, /x/)

                    if (flags ~ /\*/) {
                        mode_id = values[1]
                        mode_width = dimensions[1]
                        mode_height = dimensions[2]
                        mode_refresh = values[3]
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
            } else if (line ~ /^priority [0-9]+$/) {
                sub(/^priority /, "", line)
                priority = line
            } else if (line ~ /^Modes:[[:space:]]*/) {
                sub(/^Modes:[[:space:]]*/, "", line)
                read_modes(line)
            } else if (line ~ /^Geometry:[[:space:]]*-?[0-9]+,-?[0-9]+ [0-9]+x[0-9]+$/) {
                sub(/^Geometry:[[:space:]]*/, "", line)
                split(line, geometry, /[, x]/)
                x = geometry[1]
                y = geometry[2]
                width = geometry[3]
                height = geometry[4]
            } else if (line ~ /^Scale:[[:space:]]*[0-9.]+$/) {
                sub(/^Scale:[[:space:]]*/, "", line)
                scale = line
            } else if (line ~ /^Rotation:[[:space:]]*[0-9]+$/) {
                sub(/^Rotation:[[:space:]]*/, "", line)
                rotation = line
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

            if (line ~ /^Modes:[[:space:]]*/) {
                sub(/^Modes:[[:space:]]*/, "", line)
                count = split(line, tokens, /[[:space:]]+/)

                for (token_index = 1; token_index <= count; token_index += 1) {
                    token = tokens[token_index]

                    if (token ~ /^[0-9]+:[0-9]+x[0-9]+@[0-9.]+[*!]*$/) {
                        flags = token
                        sub(/^[^*!]*/, "", flags)
                        sub(/[*!]*$/, "", token)
                        split(token, values, /[:@]/)
                        split(values[2], dimensions, /x/)
                        preferred = flags ~ /!/ ? "true" : "false"
                        current = flags ~ /\*/ ? "true" : "false"
                        printf "%s\t%s\t%s\t%s\t%s\t%s\n", \
                            values[1], dimensions[1], dimensions[2], values[3], preferred, current
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
