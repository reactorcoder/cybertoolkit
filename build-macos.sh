#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
command -v valac >/dev/null || { echo 'Install: brew install vala gtk4'; exit 1; }
valac --pkg gtk4 --pkg gio-2.0 "$script_dir/cybertoolkit.vala" -o "$script_dir/release/cybertoolkit"
app_dir="$script_dir/CyberToolkit.app/Contents/MacOS"
mkdir -p "$app_dir"
cp "$script_dir/release/cybertoolkit" "$app_dir/CyberToolkit"
cat > "$script_dir/CyberToolkit.app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>CFBundleName</key><string>Cyber Toolkit</string><key>CFBundleExecutable</key><string>CyberToolkit</string><key>CFBundleIdentifier</key><string>com.example.cybertoolkit</string><key>CFBundleVersion</key><string>1.0</string></dict></plist>
PLIST
echo "Built CyberToolkit.app"
