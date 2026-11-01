#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v valac >/dev/null 2>&1; then
    echo 'Missing valac. Install: sudo apt install valac libgtk-4-dev' >&2
    exit 1
fi
if ! command -v pkg-config >/dev/null 2>&1 || ! pkg-config --exists gtk4; then
    echo 'Missing GTK 4 development files. Install: sudo apt install pkg-config libgtk-4-dev' >&2
    exit 1
fi
if ! command -v exiftool >/dev/null 2>&1; then
    echo 'Meta Extractor requires ExifTool: sudo apt install libimage-exiftool-perl' >&2
fi

mkdir -p "$script_dir/release"
valac --pkg gtk4 --pkg gio-2.0 "$script_dir/cybertoolkit.vala" -o "$script_dir/release/cybertoolkit"
cp -f "$script_dir"/*.html "$script_dir/release/" 2>/dev/null || true
printf 'Built %s/release/cybertoolkit\n' "$script_dir"
if pkg-config --exists gtk+-3.0 webkit2gtk-4.1; then
  valac --pkg gtk+-3.0 --pkg webkit2gtk-4.1 "$script_dir/wifi_map.vala" -o "$script_dir/wifi_map"
else
  echo 'Optional wifi_map helper not built (install libgtk-3-dev and libwebkit2gtk-4.1-dev).' >&2
fi
if pkg-config --exists gtk+-3.0 webkit2gtk-4.1; then
  valac --pkg gtk+-3.0 --pkg webkit2gtk-4.1 "$script_dir/integrated_browser.vala" -o "$script_dir/integrated_browser"
fi
