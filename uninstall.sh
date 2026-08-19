#!/usr/bin/env bash
# Uninstall Lunar Plasma for the current user.
set -euo pipefail

install_dir="$HOME/.local/share/opt/lunar-plasma"
expected_dir="$HOME/.local/share/opt/lunar-plasma"

confirm() {
    local answer

    printf '%s [y/N] ' "$1"
    read -r answer

    case "$answer" in
        y|Y|yes|Yes|YES) return 0 ;;
        *) return 1 ;;
    esac
}

if [[ -z "${HOME:-}" || "$HOME" == "/" || "$install_dir" != "$expected_dir" ]]; then
    printf 'Refusing to use an unsafe installation path: %s\n' "$install_dir" >&2
    exit 1
fi

if [[ ! -e "$install_dir" && ! -L "$install_dir" ]]; then
    printf 'Lunar Plasma is not installed in %s\n' "$install_dir"
    exit 0
fi

if [[ -L "$install_dir" ]]; then
    printf 'Installation path is a symbolic link and will not be removed: %s\n' "$install_dir" >&2
    exit 1
fi

if [[ ! -d "$install_dir" ]]; then
    printf 'Installation path exists but is not a directory: %s\n' "$install_dir" >&2
    exit 1
fi

printf 'Warning: %s and all of its contents will be removed.\n' "$install_dir"
if ! confirm "Uninstall Lunar Plasma?"; then
    printf 'Uninstallation cancelled.\n'
    exit 0
fi

rm -rf -- "$install_dir"

if [[ -e "$install_dir" || -L "$install_dir" ]]; then
    printf 'Uninstallation failed: %s still exists.\n' "$install_dir" >&2
    exit 1
fi

printf 'Lunar Plasma was uninstalled successfully.\n'
