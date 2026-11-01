#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
command -v flatpak-builder >/dev/null || { echo 'Install flatpak-builder first.' >&2; exit 1; }
if ! flatpak info org.gnome.Sdk//48 >/dev/null 2>&1; then
  echo 'Missing GNOME SDK 48. Install it with:' >&2
  echo '  flatpak install flathub org.gnome.Sdk//48' >&2
  exit 1
fi
mkdir -p "$script_dir/release"
flatpak-builder --force-clean --repo="$script_dir/release/repo" "$script_dir/release/flatpak-build" "$script_dir/com.dorksearch.CyberToolkit.yml"
flatpak build-bundle "$script_dir/release/repo" "$script_dir/release/CyberToolkit.flatpak" com.dorksearch.CyberToolkit
