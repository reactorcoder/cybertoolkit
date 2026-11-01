#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
command -v valac >/dev/null || { echo 'Install MSYS2 packages: mingw-w64-x86_64-vala mingw-w64-x86_64-gtk4'; exit 1; }
PKG_CONFIG_PATH="/mingw64/lib/pkgconfig:/mingw64/share/pkgconfig" \
valac --pkg gtk4 --pkg gio-2.0 "$script_dir/cybertoolkit.vala" -o "$script_dir/cybertoolkit.exe"
echo "Built cybertoolkit.exe"
