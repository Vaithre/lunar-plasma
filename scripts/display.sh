#!/usr/bin/env bash
# Read Plasma displays and their available modes through KScreen.
set -euo pipefail

action="${1:-}"

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

case "$action" in
    list-displays)
        list_displays
        ;;
    list-display-modes)
        list_display_modes "${2:-}"
        ;;
    *)
        printf 'unknown display action: %s\n' "$action" >&2
        exit 2
        ;;
esac
