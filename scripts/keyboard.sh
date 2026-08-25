#!/usr/bin/env bash
# Read and change keyboard layouts through Plasma D-Bus or XKB.
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

plasma_available() {
    local qdbus="$1"

    "$qdbus" org.kde.keyboard /Layouts >/dev/null 2>&1
}

plasma_layouts() {
    local qdbus="$1"
    local output

    output="$("$qdbus" --literal \
        org.kde.keyboard \
        /Layouts \
        org.kde.KeyboardLayouts.getLayoutsList)"

    sed -E 's/\], \[Argument:/\n[Argument:/g' <<<"$output" |
        sed -E 's/.*\(sss\) "([^"]*)", "([^"]*)", "([^"]*)".*/\1\t\2\t\3/' |
        awk -F '\t' 'NF == 3 { print NR "\t" $1 "\t" $2 "\t" $3 }'
}

xkb_config_value() {
    local key="$1"
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
    local config_file="$config_dir/kxkbrc"

    [[ -f "$config_file" ]] || return 1

    awk -F '=' -v key="$key" '
        /^\[Layout\]$/ { layout_section = 1; next }
        /^\[/ { layout_section = 0 }
        layout_section && $1 == key {
            sub(/^[^=]*=/, "")
            print
            exit
        }
    ' "$config_file"
}

xkb_layouts() {
    local layouts
    local variants
    local id
    local variant
    local index
    local -a layout_list
    local -a variant_list

    layouts="$(xkb_config_value LayoutList 2>/dev/null || true)"
    variants="$(xkb_config_value VariantList 2>/dev/null || true)"

    if [[ -z "$layouts" ]] && command -v setxkbmap >/dev/null 2>&1; then
        layouts="$(setxkbmap -query | awk '$1 == "layout:" { print $2 }')"
        variants="$(setxkbmap -query | awk '$1 == "variant:" { print $2 }')"
    fi

    [[ -n "$layouts" ]] || return 1

    IFS=',' read -r -a layout_list <<<"$layouts"
    IFS=',' read -r -a variant_list <<<"$variants"

    for index in "${!layout_list[@]}"; do
        id="${layout_list[index]}"
        variant="${variant_list[index]:-}"
        printf '%d\t%s\t%s\t%s\n' "$((index + 1))" "$id" "$variant" "$id"
    done
}

list_layouts() {
    local qdbus

    if qdbus="$(find_qdbus)" && plasma_available "$qdbus"; then
        plasma_layouts "$qdbus"
        return
    fi

    if xkb_layouts; then
        return
    fi

    printf 'no supported keyboard layout backend is available\n' >&2
    return 127
}

resolve_layout() {
    local selector="$1"
    local requested_variant="${2:-}"
    local index
    local id
    local variant
    local name
    local record
    local selector_lower="${selector,,}"

    while IFS= read -r record; do
        record="${record//$'\t'/$'\x1f'}"
        IFS=$'\x1f' read -r index id variant name <<<"$record"

        if [[ "$selector" == "$index" ||
            "$selector_lower" == "${id,,}" ||
            "$selector_lower" == "${name,,}" ]]; then
            if [[ -z "$requested_variant" || "$requested_variant" == "$variant" ]]; then
                printf '%s\t%s\t%s\t%s\n' "$index" "$id" "$variant" "$name"
                return
            fi
        fi
    done < <(list_layouts)

    printf 'keyboard layout not found: %s\n' "$selector" >&2
    return 1
}

get_layout() {
    local qdbus
    local active_index
    local current_id
    local current_variant
    local record

    if qdbus="$(find_qdbus)" && plasma_available "$qdbus"; then
        active_index="$("$qdbus" \
            org.kde.keyboard \
            /Layouts \
            org.kde.KeyboardLayouts.getLayout)"
        list_layouts | awk -F '\t' -v target_index="$((active_index + 1))" '$1 == target_index'
        return
    fi

    if command -v setxkbmap >/dev/null 2>&1; then
        current_id="$(setxkbmap -query | awk '$1 == "layout:" { split($2, values, ","); print values[1] }')"
        current_variant="$(setxkbmap -query | awk '$1 == "variant:" { split($2, values, ","); print values[1] }')"

        while IFS= read -r record; do
            record="${record//$'\t'/$'\x1f'}"
            IFS=$'\x1f' read -r index id variant name <<<"$record"

            if [[ "$id" == "$current_id" && "$variant" == "$current_variant" ]]; then
                printf '%s\t%s\t%s\t%s\n' "$index" "$id" "$variant" "$name"
                return
            fi
        done < <(list_layouts)
    fi

    printf 'could not determine the active keyboard layout\n' >&2
    return 1
}

set_layout() {
    local selector="$1"
    local requested_variant="${2:-}"
    local record
    local index
    local id
    local variant
    local name
    local qdbus
    local result

    record="$(resolve_layout "$selector" "$requested_variant")"
    record="${record//$'\t'/$'\x1f'}"
    IFS=$'\x1f' read -r index id variant name <<<"$record"

    if qdbus="$(find_qdbus)" && plasma_available "$qdbus"; then
        result="$("$qdbus" \
            org.kde.keyboard \
            /Layouts \
            org.kde.KeyboardLayouts.setLayout \
            "$((index - 1))")"
        [[ "$result" == "true" ]]
        return
    fi

    if command -v setxkbmap >/dev/null 2>&1; then
        if [[ -n "$variant" ]]; then
            setxkbmap -layout "$id" -variant "$variant"
        else
            setxkbmap -layout "$id"
        fi
        return
    fi

    printf 'no supported keyboard layout backend is available\n' >&2
    return 127
}

move_layout() {
    local direction="$1"
    local qdbus
    local method
    local current
    local current_index
    local count
    local target

    if qdbus="$(find_qdbus)" && plasma_available "$qdbus"; then
        if [[ "$direction" == "next" ]]; then
            method="switchToNextLayout"
        else
            method="switchToPreviousLayout"
        fi

        "$qdbus" \
            org.kde.keyboard \
            /Layouts \
            "org.kde.KeyboardLayouts.$method"
        return
    fi

    current="$(get_layout)"
    current="${current//$'\t'/$'\x1f'}"
    IFS=$'\x1f' read -r current_index _ <<<"$current"
    count="$(list_layouts | awk 'END { print NR }')"

    if [[ "$direction" == "next" ]]; then
        target=$((current_index % count + 1))
    else
        target=$(((current_index + count - 2) % count + 1))
    fi

    set_layout "$target"
}

case "$action" in
    list-layouts)
        list_layouts
        ;;
    get-layout)
        get_layout
        ;;
    set-layout)
        set_layout "${2:-}" "${3:-}"
        ;;
    next-layout)
        move_layout next
        ;;
    previous-layout)
        move_layout previous
        ;;
    *)
        printf 'unknown keyboard action: %s\n' "$action" >&2
        exit 2
        ;;
esac
