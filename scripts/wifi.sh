#!/usr/bin/env bash
# Read and change Wi-Fi state through NetworkManager.
set -euo pipefail

export LC_ALL=C

action="${1:-}"

require_nmcli() {
    if ! command -v nmcli >/dev/null 2>&1; then
        printf 'nmcli is required to control the Wi-Fi backend\n' >&2
        return 127
    fi
}

wifi_enabled() {
    local state

    state="$(nmcli radio wifi)"

    case "$state" in
        enabled) printf 'true\n' ;;
        disabled) printf 'false\n' ;;
        *)
            printf 'could not determine the Wi-Fi radio state\n' >&2
            return 1
            ;;
    esac
}

connected_device() {
    nmcli --terse --fields DEVICE,TYPE,STATE device status |
        awk -F ':' '$2 == "wifi" && $3 == "connected" { print $1; exit }'
}

active_network() {
    local device="$1"
    local active
    local network

    while IFS=: read -r active network; do
        if [[ "$active" == "*" ]]; then
            printf '%s\n' "$network"
            return
        fi
    done < <(nmcli --terse --escape no --fields IN-USE,SSID device wifi list ifname "$device")

    printf 'could not determine the active Wi-Fi network\n' >&2
    return 1
}

get_status() {
    local enabled
    local device
    local network=""
    local connected=false

    enabled="$(wifi_enabled)"

    if [[ "$enabled" == "true" ]]; then
        device="$(connected_device)"

        if [[ -n "$device" ]]; then
            connected=true
            network="$(active_network "$device")"
        fi
    fi

    printf '%s\t%s\t%s\n' "$enabled" "$connected" "$network"
}

set_enabled() {
    local state="$1"

    nmcli radio wifi "$state"
}

toggle_wifi() {
    if [[ "$(wifi_enabled)" == "true" ]]; then
        set_enabled off
    else
        set_enabled on
    fi
}

require_nmcli

case "$action" in
    get-status)
        get_status
        ;;
    enable)
        set_enabled on
        ;;
    disable)
        set_enabled off
        ;;
    toggle)
        toggle_wifi
        ;;
    *)
        printf 'unknown wifi action: %s\n' "$action" >&2
        exit 2
        ;;
esac
