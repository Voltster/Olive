#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🫒 Building Olive for macOS (Release)..."
cd "$ROOT_DIR"

# 1. Compile release binary
swift build -c release

RELEASE_BIN="$ROOT_DIR/.build/release/Olive"
APP_BUNDLE="$ROOT_DIR/build/Olive.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "📦 Packaging Olive.app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS" "$RESOURCES"

# 2. Copy binary
cp "$RELEASE_BIN" "$MACOS/Olive"
chmod +x "$MACOS/Olive"

# 3. Generate Info.plist
cat << 'EOF' > "$CONTENTS/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Olive</string>
    <key>CFBundleIdentifier</key>
    <string>com.voltster.olive</string>
    <key>CFBundleName</key>
    <string>Olive</string>
    <key>CFBundleDisplayName</key>
    <string>Olive</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Voltster. Released under GPL-3.0.</string>
</dict>
</plist>
EOF

# 4. Generate App Icon
echo "🎨 Generating App Icon..."
TEMP_ICONSET="$ROOT_DIR/build/AppIcon.iconset"
rm -rf "$TEMP_ICONSET"
mkdir -p "$TEMP_ICONSET"

swift "$SCRIPT_DIR/generate_app_icon.swift" "$ROOT_DIR/build/AppIcon_1024.png"

sips -z 16 16     "$ROOT_DIR/build/AppIcon_1024.png" --out "$TEMP_ICONSET/icon_16x16.png" > /dev/null
sips -z 32 32     "$ROOT_DIR/build/AppIcon_1024.png" --out "$TEMP_ICONSET/icon_16x16@2x.png" > /dev/null
sips -z 32 32     "$ROOT_DIR/build/AppIcon_1024.png" --out "$TEMP_ICONSET/icon_32x32.png" > /dev/null
sips -z 64 64     "$ROOT_DIR/build/AppIcon_1024.png" --out "$TEMP_ICONSET/icon_32x32@2x.png" > /dev/null
sips -z 128 128   "$ROOT_DIR/build/AppIcon_1024.png" --out "$TEMP_ICONSET/icon_128x128.png" > /dev/null
sips -z 256 256   "$ROOT_DIR/build/AppIcon_1024.png" --out "$TEMP_ICONSET/icon_128x128@2x.png" > /dev/null
sips -z 256 256   "$ROOT_DIR/build/AppIcon_1024.png" --out "$TEMP_ICONSET/icon_256x256.png" > /dev/null
sips -z 512 512   "$ROOT_DIR/build/AppIcon_1024.png" --out "$TEMP_ICONSET/icon_256x256@2x.png" > /dev/null
sips -z 512 512   "$ROOT_DIR/build/AppIcon_1024.png" --out "$TEMP_ICONSET/icon_512x512.png" > /dev/null
sips -z 1024 1024 "$ROOT_DIR/build/AppIcon_1024.png" --out "$TEMP_ICONSET/icon_512x512@2x.png" > /dev/null

iconutil -c icns "$TEMP_ICONSET" -o "$RESOURCES/AppIcon.icns"
rm -rf "$TEMP_ICONSET"

# 5. Create DMG Installer
echo "💿 Generating Olive.dmg installer..."
DMG_STAGING="$ROOT_DIR/build/dmg_staging"
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"

cp -R "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

DMG_OUTPUT="$ROOT_DIR/build/Olive-1.0.0.dmg"
rm -f "$DMG_OUTPUT"

hdiutil create -volname "Olive" -srcfolder "$DMG_STAGING" -ov -format UDZO "$DMG_OUTPUT"
rm -rf "$DMG_STAGING"

echo ""
echo "✅ Build Complete!"
echo "📍 Application Bundle: $APP_BUNDLE"
echo "📍 DMG Installer:     $DMG_OUTPUT"
echo ""
echo "You can drag '$APP_BUNDLE' directly into your /Applications folder to install!"
