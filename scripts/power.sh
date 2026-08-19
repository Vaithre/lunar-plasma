#!/usr/bin/env bash
# Control power management through standard and Plasma D-Bus interfaces.
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

set_profile() {
    local profile="$1"
    local available_profiles
    local qdbus

    if command -v busctl >/dev/null 2>&1 &&
        available_profiles="$(busctl --system get-property \
            net.hadess.PowerProfiles \
            /net/hadess/PowerProfiles \
            net.hadess.PowerProfiles \
            Profiles 2>/dev/null)"; then
        if [[ "$available_profiles" != *\"$profile\"* ]]; then
            printf 'power profile is not available: %s\n' "$profile" >&2
            return 1
        fi

        if busctl --system set-property \
            net.hadess.PowerProfiles \
            /net/hadess/PowerProfiles \
            net.hadess.PowerProfiles \
            ActiveProfile s "$profile"; then
            return
        fi
    fi

    if command -v powerprofilesctl >/dev/null 2>&1; then
        if powerprofilesctl set "$profile"; then
            return
        fi
    fi

    if qdbus="$(find_qdbus)"; then
        available_profiles="$("$qdbus" \
            org.kde.Solid.PowerManagement \
            /org/kde/Solid/PowerManagement/Actions/PowerProfile \
            org.kde.Solid.PowerManagement.Actions.PowerProfile.profileChoices)"

        if ! grep -Fxq "$profile" <<<"$available_profiles"; then
            printf 'power profile is not available: %s\n' "$profile" >&2
            return 1
        fi

        "$qdbus" \
            org.kde.Solid.PowerManagement \
            /org/kde/Solid/PowerManagement/Actions/PowerProfile \
            org.kde.Solid.PowerManagement.Actions.PowerProfile.setProfile \
            "$profile"
        return
    fi

    printf 'no supported power profile backend is available\n' >&2
    return 127
}

suspend_system() {
    local qdbus

    if qdbus="$(find_qdbus)" && "$qdbus" \
        org.kde.Solid.PowerManagement \
        /org/kde/Solid/PowerManagement/Actions/SuspendSession \
        org.kde.Solid.PowerManagement.Actions.SuspendSession.suspendToRam; then
        return
    fi

    if command -v busctl >/dev/null 2>&1 && busctl --system call \
            org.freedesktop.login1 \
            /org/freedesktop/login1 \
            org.freedesktop.login1.Manager \
            Suspend b true; then
        return
    fi

    if command -v systemctl >/dev/null 2>&1; then
        systemctl suspend
        return
    fi

    printf 'no supported suspend backend is available\n' >&2
    return 127
}

system_power_action() {
    local method="$1"
    local fallback="$2"

    if command -v busctl >/dev/null 2>&1 && busctl --system call \
            org.freedesktop.login1 \
            /org/freedesktop/login1 \
            org.freedesktop.login1.Manager \
            "$method" b true; then
        return
    fi

    if command -v systemctl >/dev/null 2>&1; then
        systemctl "$fallback"
        return
    fi

    printf 'no supported system power backend is available\n' >&2
    return 127
}

resolve_display() {
    local qdbus="$1"
    local selector="$2"
    local selector_lower="${selector,,}"
    local selector_compact="${selector_lower// /}"
    local display
    local label
    local index
    local position
    local marker
    local output_id
    local output_name
    local output_uuid
    local remainder
    local -a displays

    mapfile -t displays < <("$qdbus" \
        org.kde.ScreenBrightness \
        /org/kde/ScreenBrightness \
        org.kde.ScreenBrightness.DisplaysDBusNames)

    if [[ "$selector_compact" =~ ^(monitor|screen)-?([0-9]+)$ ]]; then
        index="${BASH_REMATCH[2]}"
    elif [[ "$selector" =~ ^[0-9]+$ ]]; then
        index="$selector"
    fi

    if [[ -n "${index:-}" ]] && (( index >= 1 && index <= ${#displays[@]} )); then
        printf '%s\n' "${displays[index - 1]}"
        return
    fi

    for display in "${displays[@]}"; do
        if [[ "$selector_lower" == "${display,,}" ||
            "$selector_lower" == "/org/kde/screenbrightness/${display,,}" ]]; then
            printf '%s\n' "$display"
            return
        fi

        label="$("$qdbus" \
            org.kde.ScreenBrightness \
            "/org/kde/ScreenBrightness/$display" \
            org.kde.ScreenBrightness.Display.Label)"

        if [[ "$selector_lower" == "${label,,}" ]]; then
            printf '%s\n' "$display"
            return
        fi
    done

    if command -v kscreen-doctor >/dev/null 2>&1; then
        position=0

        while read -r marker output_id output_name output_uuid remainder; do
            [[ "$marker" == "Output:" ]] || continue
            ((position += 1))

            if [[ "$selector_lower" == "${output_name,,}" ||
                "$selector_lower" == "${output_uuid,,}" ]]; then
                if (( position <= ${#displays[@]} )); then
                    printf '%s\n' "${displays[position - 1]}"
                    return
                fi
            fi
        done < <(NO_COLOR=1 kscreen-doctor -o 2>/dev/null |
            sed -E $'s/\x1B\[[0-9;]*[mK]//g')
    fi

    printf 'display not found: %s\n' "$selector" >&2
    return 1
}

set_brightness() {
    local selector="$1"
    local percentage="$2"
    local qdbus
    local display
    local maximum
    local brightness

    if ! qdbus="$(find_qdbus)"; then
        printf 'qdbus is required to control display brightness\n' >&2
        return 127
    fi

    display="$(resolve_display "$qdbus" "$selector")"
    maximum="$("$qdbus" \
        org.kde.ScreenBrightness \
        "/org/kde/ScreenBrightness/$display" \
        org.kde.ScreenBrightness.Display.MaxBrightness)"

    if [[ ! "$maximum" =~ ^[0-9]+$ ]] || (( maximum <= 0 )); then
        printf 'invalid maximum brightness for display: %s\n' "$selector" >&2
        return 1
    fi

    brightness=$(( (percentage * maximum + 50) / 100 ))

    "$qdbus" \
        org.kde.ScreenBrightness \
        "/org/kde/ScreenBrightness/$display" \
        org.kde.ScreenBrightness.Display.SetBrightness \
        "$brightness" 0
}

get_brightness() {
    local selector="$1"
    local qdbus
    local display
    local current
    local maximum
    local percentage

    if ! qdbus="$(find_qdbus)"; then
        printf 'qdbus is required to read display brightness\n' >&2
        return 127
    fi

    display="$(resolve_display "$qdbus" "$selector")"
    current="$("$qdbus" \
        org.kde.ScreenBrightness \
        "/org/kde/ScreenBrightness/$display" \
        org.kde.ScreenBrightness.Display.Brightness)"
    maximum="$("$qdbus" \
        org.kde.ScreenBrightness \
        "/org/kde/ScreenBrightness/$display" \
        org.kde.ScreenBrightness.Display.MaxBrightness)"

    if [[ ! "$current" =~ ^[0-9]+$ || ! "$maximum" =~ ^[0-9]+$ ]] ||
        (( maximum <= 0 )); then
        printf 'invalid brightness state for display: %s\n' "$selector" >&2
        return 1
    fi

    percentage=$(( (current * 100 + maximum / 2) / maximum ))
    printf '%d\n' "$percentage"
}

case "$action" in
    set-profile)
        set_profile "${2:-}"
        ;;
    suspend)
        suspend_system
        ;;
    shutdown)
        system_power_action PowerOff poweroff
        ;;
    reboot)
        system_power_action Reboot reboot
        ;;
    set-brightness)
        set_brightness "${2:-}" "${3:-}"
        ;;
    get-brightness)
        get_brightness "${2:-}"
        ;;
    *)
        printf 'unknown power action: %s\n' "$action" >&2
        exit 2
        ;;
esac
