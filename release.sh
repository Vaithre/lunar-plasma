#!/usr/bin/env bash
# Build a clean Lunar Plasma release archive.
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
version_file="$project_root/VERSION"
changelog_file="$project_root/CHANGELOG.md"

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        printf 'Required command not found: %s\n' "$1" >&2
        return 1
    fi
}

require_command tar
require_command date

if [[ ! -f "$version_file" ]]; then
    printf 'Missing release file: VERSION\n' >&2
    exit 1
fi

if [[ ! -f "$changelog_file" ]]; then
    printf 'Missing release file: CHANGELOG.md\n' >&2
    exit 1
fi

version="$(tr -d '[:space:]' <"$version_file")"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z]+)*$ ]]; then
    printf 'Invalid VERSION value: %s\n' "$version" >&2
    exit 1
fi

release_heading="$(awk '/^## \[[^]]+\] - / { print; exit }' "$changelog_file")"

if [[ ! "$release_heading" =~ ^##\ \[([^]]+)\]\ -\ (.+)$ ]]; then
    printf 'Could not find the current release heading in CHANGELOG.md\n' >&2
    exit 1
fi

changelog_version="${BASH_REMATCH[1]}"
release_date="${BASH_REMATCH[2]}"

if [[ "$changelog_version" != "$version" ]]; then
    printf 'Release version mismatch: VERSION is %s, CHANGELOG.md is %s\n' \
        "$version" "$changelog_version" >&2
    exit 1
fi

if [[ ! "$release_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] ||
    [[ "$(date -d "$release_date" +%F 2>/dev/null || true)" != "$release_date" ]]; then
    printf 'Release %s does not have a valid final date in CHANGELOG.md\n' "$version" >&2
    exit 1
fi

package_name="lunar-plasma-$version"
archive="$project_root/$package_name.tar.gz"
temporary_archive="$project_root/.$package_name.tar.gz.tmp"
project_sources=()

while IFS= read -r -d '' source; do
    project_sources+=("$(basename -- "$source")")
done < <(
    {
        find "$project_root" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -print0
        find "$project_root" -mindepth 1 -maxdepth 1 -type f -name '*.md' -print0
        printf '%s\0' \
            "$project_root/install.sh" \
            "$project_root/uninstall.sh" \
            "$project_root/lunar-plasma.lua" \
            "$project_root/release.sh" \
            "$project_root/LICENSE" \
            "$project_root/VERSION"
    } |
        sort -z
)

if [[ "${#project_sources[@]}" -eq 0 ]]; then
    printf 'No release sources found\n' >&2
    exit 1
fi

for source in "${project_sources[@]}"; do
    if [[ ! -e "$project_root/$source" ]]; then
        printf 'Missing release source: %s\n' "$source" >&2
        exit 1
    fi
done

if [[ -e "$archive" ]]; then
    printf 'Release archive already exists: %s\n' "$archive" >&2
    exit 1
fi

cleanup() {
    rm -f -- "$temporary_archive"
}

trap cleanup EXIT

tar \
    --create \
    --gzip \
    --file="$temporary_archive" \
    --directory="$project_root" \
    --sort=name \
    --format=posix \
    --pax-option=delete=atime,delete=ctime \
    --no-acls \
    --no-selinux \
    --no-xattrs \
    --owner=0 \
    --group=0 \
    --numeric-owner \
    --mode='u+rwX,go+rX,go-w' \
    --mtime="$release_date 00:00:00 UTC" \
    --transform="s,^,$package_name/," \
    "${project_sources[@]}"

mv -- "$temporary_archive" "$archive"
trap - EXIT

printf 'Created release archive: %s\n' "$archive"
