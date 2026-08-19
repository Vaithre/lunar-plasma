#!/usr/bin/env bash
# Install Lunar Plasma for the current user.
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
install_root="$HOME/.local/share/opt"
install_dir="$install_root/lunar-plasma"
expected_dir="$HOME/.local/share/opt/lunar-plasma"
staging_dir=""
backup_dir=""

cleanup() {
    if [[ -n "$staging_dir" && -d "$staging_dir" ]]; then
        rm -rf -- "$staging_dir"
    fi
}

confirm() {
    local answer

    printf '%s [y/N] ' "$1"
    read -r answer

    case "$answer" in
        y|Y|yes|Yes|YES) return 0 ;;
        *) return 1 ;;
    esac
}

verify_sources() {
    local source

    for source in examples lua scripts resources/Nexus.png lunar-plasma.lua VERSION; do
        if [[ ! -e "$project_root/$source" ]]; then
            printf 'Missing installation source: %s\n' "$source" >&2
            return 1
        fi
    done
}

verify_installation() {
    [[ -d "$install_dir/examples" ]] || return 1
    [[ -d "$install_dir/lua" ]] || return 1
    [[ -d "$install_dir/resources" ]] || return 1
    [[ -d "$install_dir/scripts" ]] || return 1
    [[ -f "$install_dir/lunar-plasma.lua" ]] || return 1
    [[ -f "$install_dir/VERSION" ]] || return 1
    [[ -f "$install_dir/resources/Nexus.png" ]] || return 1

    diff -qr "$project_root/examples" "$install_dir/examples" >/dev/null || return 1
    diff -qr "$project_root/lua" "$install_dir/lua" >/dev/null || return 1
    diff -qr "$project_root/scripts" "$install_dir/scripts" >/dev/null || return 1
    cmp -s "$project_root/lunar-plasma.lua" "$install_dir/lunar-plasma.lua" || return 1
    cmp -s "$project_root/VERSION" "$install_dir/VERSION" || return 1
    cmp -s "$project_root/resources/Nexus.png" "$install_dir/resources/Nexus.png" || return 1

    local executable
    for executable in "$install_dir/scripts/"*.sh "$install_dir/examples/"*.lua; do
        [[ -x "$executable" ]] || return 1
    done

    [[ "$(find "$install_dir/resources" -maxdepth 1 -type f | wc -l)" -eq 1 ]]
}

if [[ -z "${HOME:-}" || "$HOME" == "/" || "$install_dir" != "$expected_dir" ]]; then
    printf 'Refusing to use an unsafe installation path: %s\n' "$install_dir" >&2
    exit 1
fi

verify_sources

if [[ -L "$install_dir" ]]; then
    printf 'Installation path is a symbolic link: %s\n' "$install_dir" >&2
    exit 1
fi

if [[ -e "$install_dir" && ! -d "$install_dir" ]]; then
    printf 'Installation path exists but is not a directory: %s\n' "$install_dir" >&2
    exit 1
fi

if [[ ! -e "$install_dir" ]]; then
    if ! confirm "Create $install_dir and install Lunar Plasma?"; then
        printf 'Installation cancelled.\n'
        exit 0
    fi
elif [[ -z "$(find "$install_dir" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
    if ! confirm "The installation directory is empty. Install Lunar Plasma here?"; then
        printf 'Installation cancelled.\n'
        exit 0
    fi
else
    printf 'Warning: every file inside %s will be removed.\n' "$install_dir"
    if ! confirm "Replace it with this version of Lunar Plasma?"; then
        printf 'Installation cancelled.\n'
        exit 0
    fi
fi

mkdir -p -- "$install_root"
staging_dir="$(mktemp -d "$install_root/.lunar-plasma-install.XXXXXX")"
trap cleanup EXIT

mkdir -p -- "$staging_dir/package/resources"
cp -a -- "$project_root/examples" "$staging_dir/package/"
cp -a -- "$project_root/lua" "$staging_dir/package/"
cp -a -- "$project_root/scripts" "$staging_dir/package/"
cp -a -- "$project_root/resources/Nexus.png" "$staging_dir/package/resources/"
cp -a -- "$project_root/lunar-plasma.lua" "$staging_dir/package/"
cp -a -- "$project_root/VERSION" "$staging_dir/package/"

# ZIP archives may not preserve executable permissions.
chmod +x -- "$staging_dir/package/scripts/"*.sh
chmod +x -- "$staging_dir/package/examples/"*.lua

if [[ -d "$install_dir" ]]; then
    backup_dir="$staging_dir/previous"
    mv -- "$install_dir" "$backup_dir"
fi

if ! mv -- "$staging_dir/package" "$install_dir"; then
    if [[ -n "$backup_dir" && -d "$backup_dir" ]]; then
        mv -- "$backup_dir" "$install_dir"
    fi

    printf 'Installation failed while moving files into place.\n' >&2
    exit 1
fi

if ! verify_installation; then
    rm -rf -- "$install_dir"

    if [[ -n "$backup_dir" && -d "$backup_dir" ]]; then
        mv -- "$backup_dir" "$install_dir"
    fi

    printf 'Installation verification failed. The previous installation was restored.\n' >&2
    exit 1
fi

if [[ -n "$backup_dir" && -d "$backup_dir" ]]; then
    rm -rf -- "$backup_dir"
fi

printf 'Lunar Plasma was installed successfully in %s\n' "$install_dir"
