#!/usr/bin/env bash
set -euo pipefail

command_name="$(basename "$0")"
scenario="${LUNAR_MOCK_SCENARIO:-default}"

if [[ -n "${LUNAR_MOCK_LOG:-}" ]]; then
    {
        printf '%s' "$command_name"
        printf '\t%s' "$@"
        printf '\n'
    } >>"$LUNAR_MOCK_LOG"
fi

case "$command_name" in
    pactl)
        case "$*" in
            "get-sink-volume @DEFAULT_SINK@") printf 'Volume: front-left: 26214 / 40%% / -23.88 dB\n' ;;
            "get-sink-mute @DEFAULT_SINK@") [[ "$scenario" == "invalid-mute" ]] && printf 'Mute: unknown\n' || printf 'Mute: no\n' ;;
            set-sink-volume*|set-sink-mute*) ;;
            *) exit 2 ;;
        esac
        ;;
    notify-send)
        ;;
    nmcli)
        if [[ "$*" == "radio wifi" ]]; then
            [[ "$scenario" == "wifi-disabled" ]] && printf 'disabled\n' || printf 'enabled\n'
        elif [[ "$*" == "--terse --fields DEVICE,TYPE,STATE device status" ]]; then
            [[ "$scenario" == "wifi-disconnected" ]] || printf 'wlan0:wifi:connected\neth0:ethernet:connected\n'
        elif [[ "$*" == "--terse --escape no --fields IN-USE,SSID device wifi list ifname wlan0" ]]; then
            printf ':Other network\n*:Lunar Network\n'
        elif [[ "$*" == "radio wifi on" || "$*" == "radio wifi off" ]]; then
            :
        else
            exit 2
        fi
        ;;
    bluetoothctl)
        shift 2
        case "${1:-}" in
            list) printf 'Controller AA:BB:CC:DD:EE:FF Lunar Adapter [default]\n' ;;
            show) printf 'Controller AA:BB:CC:DD:EE:FF Lunar Adapter\n\tName: Lunar Adapter\n\tPowered: yes\n\tDiscoverable: no\n\tDiscovering: no\n' ;;
            devices) printf 'Device 11:22:33:44:55:66 Lunar Headphones\nDevice 77:88:99:AA:BB:CC Lunar Controller\n' ;;
            info)
                if [[ "${2:-}" == "11:22:33:44:55:66" ]]; then printf 'Device 11:22:33:44:55:66\n\tName: Lunar Headphones\n\tPaired: yes\n\tTrusted: yes\n\tConnected: yes\n\tBlocked: no\n'
                else printf 'Device 77:88:99:AA:BB:CC\n\tName: Lunar Controller\n\tPaired: yes\n\tTrusted: no\n\tConnected: no\n\tBlocked: no\n'; fi
                ;;
            power) ;;
            *) exit 2 ;;
        esac
        ;;
    kscreen-doctor)
        printf 'Output: 1 eDP-1 panel-uuid\n\tenabled\n\tconnected\n\tpriority 1\n\tModes: 1:1280x720@60! 2:1920x1080@59.94*\n\tGeometry: -10,20 1920x1080\n\tScale: 1.25\n\tRotation: 1\nOutput: 2 HDMI-A-1 hdmi-uuid\n\tconnected\n\tpriority 0\n\tModes: 3:2560x1440@144!\n\tGeometry: 1910,20 2560x1440\n\tScale: 1\n\tRotation: 2\n'
        ;;
    qdbus-qt6|qdbus6|qdbus-qt5|qdbus)
        case "$*" in
            "org.kde.keyboard /Layouts") ;;
            *getLayoutsList*) printf '[Argument: a(sss) {[Argument: (sss) "latam", "", "Spanish"], [Argument: (sss) "us", "intl", "English"]}]\n' ;;
            *getLayout*) printf '0\n' ;;
            *setLayout*) printf 'true\n' ;;
            *switchToNextLayout*|*switchToPreviousLayout*) ;;
            *DisplaysDBusNames*) printf 'display0\ndisplay1\n' ;;
            *display0*Display.Label*) printf 'Internal Display\n' ;;
            *display1*Display.Label*) printf 'External Display\n' ;;
            *MaxBrightness*) printf '1000\n' ;;
            *Display.Brightness*) printf '400\n' ;;
            *SetBrightness*) ;;
            *screenForConnector*) printf '0\n' ;;
            *org.kde.PlasmaShell.wallpaper*)
                if [[ "$*" == *' 0' ]]; then printf 'a{sv} {"wallpaperPlugin" = [Variant(QString): "org.kde.image"], "Image" = [Variant(QString): "file:///tmp/wallpaper.png"]}\n'
                else printf 'a{sv} {}\n'; exit 1; fi
                ;;
            *currentProfile*) printf 'balanced\n' ;;
            *profileChoices*) printf 'power-saver\nbalanced\nperformance\n' ;;
            *setProfile*|*suspendToRam*) ;;
            *) exit 2 ;;
        esac
        ;;
    busctl)
        if [[ "$scenario" == "busctl-fails" || "$scenario" == "dbus-fails" ]]; then printf 'busctl failure\n' >&2; exit 1; fi
        if [[ "$*" == *"ActiveProfile"* ]]; then printf 's "balanced"\n'
        elif [[ "$*" == *"Profiles"* ]]; then printf 'a(ss) 3 "power-saver" "" "balanced" "" "performance" ""\n'
        elif [[ "$*" == *"IsPresent"* ]]; then printf 'b true\n'
        elif [[ "$*" == *"OnBattery"* ]]; then printf 'b true\n'
        elif [[ "$*" == *"Percentage"* ]]; then printf 'd 73.4\n'
        elif [[ "$*" == *"State"* ]]; then printf 'u 2\n'
        elif [[ "$*" == *"WarningLevel"* ]]; then printf 'u 3\n'
        elif [[ "$*" == *"TimeToEmpty"* ]]; then printf 'x 7200\n'
        else :; fi
        ;;
    gdbus)
        [[ "$scenario" == "dbus-fails" ]] && { printf 'gdbus failure\n' >&2; exit 1; }
        printf "()\n"
        ;;
    powerprofilesctl|systemctl|setxkbmap)
        if [[ "$command_name" == "powerprofilesctl" && "${1:-}" == get ]]; then printf 'balanced\n'; fi
        if [[ "$command_name" == "setxkbmap" && "${1:-}" == -query ]]; then printf 'rules: evdev\nlayout: latam,us\nvariant: ,intl\n'; fi
        ;;
    realpath)
        /usr/bin/realpath "$@"
        ;;
    *) exit 127 ;;
esac
