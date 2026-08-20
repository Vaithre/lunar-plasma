#!/usr/bin/env bash
# Read and change Bluetooth state through BlueZ.
set -euo pipefail

export LC_ALL=C

action="${1:-}"
bluetooth_timeout="${LUNAR_PLASMA_BLUETOOTH_TIMEOUT:-2}"

require_bluetoothctl() {
    if ! command -v bluetoothctl >/dev/null 2>&1; then
        printf 'bluetoothctl is required to control the Bluetooth backend\n' >&2
        return 127
    fi
}

run_bluetoothctl() {
    bluetoothctl --timeout "$bluetooth_timeout" "$@"
}

require_adapter() {
    local controllers

    if [[ ! -d /sys/class/bluetooth ]] ||
        ! compgen -G '/sys/class/bluetooth/hci*' >/dev/null; then
        printf 'no Bluetooth adapter is available\n' >&2
        return 1
    fi

    if ! controllers="$(run_bluetoothctl list)"; then
        printf 'could not query available Bluetooth adapters\n' >&2
        return 1
    fi

    if ! awk '$1 == "Controller" { found = 1 } END { exit !found }' <<<"$controllers"; then
        printf 'no Bluetooth adapter is available\n' >&2
        return 1
    fi
}

property_value() {
    local output="$1"
    local property="$2"

    awk -F ':' -v property="$property" '
        $1 ~ "^[[:space:]]*" property "$" {
            sub(/^[^:]*:[[:space:]]*/, "")
            print
            exit
        }
    ' <<<"$output"
}

boolean_value() {
    case "$1" in
        yes) printf 'true\n' ;;
        no) printf 'false\n' ;;
        *)
            printf 'invalid Bluetooth boolean value: %s\n' "$1" >&2
            return 1
            ;;
    esac
}

normalize_name() {
    local name="$1"

    name="${name//$'\t'/ }"
    name="${name//$'\n'/ }"
    printf '%s\n' "$name"
}

get_status() {
    local info
    local address
    local name
    local enabled
    local discoverable
    local discovering

    info="$(run_bluetoothctl show)"
    address="$(awk '$1 == "Controller" { print $2; exit }' <<<"$info")"

    if [[ -z "$address" ]]; then
        printf 'no default Bluetooth adapter is available\n' >&2
        return 1
    fi

    name="$(property_value "$info" Name)"
    name="$(normalize_name "$name")"
    enabled="$(boolean_value "$(property_value "$info" Powered)")"
    discoverable="$(boolean_value "$(property_value "$info" Discoverable)")"
    discovering="$(boolean_value "$(property_value "$info" Discovering)")"

    if [[ -z "$name" ]]; then
        printf 'could not determine the default Bluetooth adapter name\n' >&2
        return 1
    fi

    printf '%s\t%s\t%s\t%s\t%s\n' \
        "$enabled" "$discoverable" "$discovering" "$address" "$name"
}

known_device_addresses() {
    run_bluetoothctl devices |
        awk '$1 == "Device" && $2 ~ /^([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}$/ { print $2 }'
}

get_device() {
    local requested_address="$1"
    local info
    local address
    local name
    local paired
    local trusted
    local connected
    local blocked

    if [[ ! "$requested_address" =~ ^([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}$ ]]; then
        printf 'invalid Bluetooth device address: %s\n' "$requested_address" >&2
        return 2
    fi

    info="$(run_bluetoothctl info "$requested_address")"
    address="$(awk '$1 == "Device" { print $2; exit }' <<<"$info")"

    if [[ -z "$address" ]]; then
        printf 'Bluetooth device not found: %s\n' "$requested_address" >&2
        return 1
    fi

    name="$(property_value "$info" Name)"
    name="$(normalize_name "$name")"
    paired="$(boolean_value "$(property_value "$info" Paired)")"
    trusted="$(boolean_value "$(property_value "$info" Trusted)")"
    connected="$(boolean_value "$(property_value "$info" Connected)")"
    blocked="$(boolean_value "$(property_value "$info" Blocked)")"

    if [[ -z "$name" ]]; then
        printf 'could not determine the Bluetooth device name: %s\n' "$address" >&2
        return 1
    fi

    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$address" "$paired" "$trusted" "$connected" "$blocked" "$name"
}

list_devices() {
    local address

    while IFS= read -r address; do
        [[ -n "$address" ]] || continue
        get_device "$address"
    done < <(known_device_addresses)
}

list_connected_devices() {
    list_devices | awk -F '\t' '$4 == "true"'
}

set_enabled() {
    local state="$1"

    run_bluetoothctl power "$state" >/dev/null
}

toggle_bluetooth() {
    local info
    local enabled

    info="$(run_bluetoothctl show)"
    enabled="$(boolean_value "$(property_value "$info" Powered)")"

    if [[ "$enabled" == "true" ]]; then
        set_enabled off
    else
        set_enabled on
    fi
}

require_bluetoothctl

if [[ ! "$bluetooth_timeout" =~ ^[1-9][0-9]*$ ]]; then
    printf 'LUNAR_PLASMA_BLUETOOTH_TIMEOUT must be a positive integer\n' >&2
    exit 2
fi

require_adapter

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
        toggle_bluetooth
        ;;
    list-devices)
        list_devices
        ;;
    list-connected-devices)
        list_connected_devices
        ;;
    get-device)
        get_device "${2:-}"
        ;;
    *)
        printf 'unknown Bluetooth action: %s\n' "$action" >&2
        exit 2
        ;;
esac
