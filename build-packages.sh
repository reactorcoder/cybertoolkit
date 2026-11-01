#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
release="$script_dir/release"
mkdir -p "$release"
"$script_dir/build-linux.sh"

# Debian package
pkg="$release/cybertoolkit-deb"
rm -rf "$pkg"
mkdir -p "$pkg/DEBIAN" "$pkg/usr/bin" "$pkg/usr/share/cybertoolkit" "$pkg/usr/share/icons/hicolor/scalable/apps"
cp "$release/cybertoolkit" "$pkg/usr/bin/cybertoolkit"
cp -f "$release"/*.html "$pkg/usr/share/cybertoolkit/" 2>/dev/null || true
cp "$script_dir/cybertoolkit.svg" "$pkg/usr/share/icons/hicolor/scalable/apps/cybertoolkit.svg"
cat > "$pkg/DEBIAN/control" <<CTRL
Package: cybertoolkit
Version: 1.0.0
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Cyber Toolkit
Description: Cybersecurity and OSINT research toolkit
 GTK4 desktop toolkit for authorized security research.
CTRL
dpkg-deb --build --root-owner-group "$pkg" "$release/cybertoolkit_1.0.0_amd64.deb" >/dev/null
rm -rf "$pkg"

# AppImage (requires appimagetool)
appdir="$release/CyberToolkit.AppDir"
rm -rf "$appdir"
mkdir -p "$appdir/usr/bin" "$appdir/usr/share/cybertoolkit" "$appdir/usr/share/applications" "$appdir/usr/share/icons/hicolor/scalable/apps"
cp "$release/cybertoolkit" "$appdir/usr/bin/cybertoolkit"
cp -f "$release"/*.html "$appdir/usr/share/cybertoolkit/" 2>/dev/null || true
cp "$script_dir/cybertoolkit.svg" "$appdir/usr/share/icons/hicolor/scalable/apps/cybertoolkit.svg"
cat > "$appdir/cybertoolkit.desktop" <<DESKTOP
[Desktop Entry]
Name=Cyber Toolkit
Exec=cybertoolkit
Type=Application
Categories=Utility;Security;
Icon=cybertoolkit
DESKTOP
cp "$appdir/cybertoolkit.desktop" "$appdir/usr/share/applications/"
cat > "$appdir/AppRun" <<'RUN'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
cd "$HERE/usr/share/cybertoolkit"
exec "$HERE/usr/bin/cybertoolkit" "$@"
RUN
chmod +x "$appdir/AppRun"
if command -v appimagetool >/dev/null 2>&1; then
  appimagetool "$appdir" "$release/CyberToolkit-x86_64.AppImage" >/dev/null
  rm -rf "$appdir"
else
  echo "AppImage not created: install appimagetool; AppDir is at $appdir" >&2
fi
printf 'Packages are in %s\n' "$release"
