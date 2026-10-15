#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build/Nailong.app/Contents/{MacOS,Resources} build/module-cache
xcrun swiftc Sources/*.swift -o build/Nailong.app/Contents/MacOS/Nailong -framework AppKit -framework ApplicationServices -framework ScreenCaptureKit -framework Vision -module-cache-path build/module-cache
cp Assets/nailong-atlas.png build/Nailong.app/Contents/Resources/
cat > build/Nailong.app/Contents/Info.plist <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Nailong</string>
<key>CFBundleIdentifier</key><string>local.nailong.desktop</string>
<key>CFBundleName</key><string>Nailong</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>0.3.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - build/Nailong.app
printf 'Built build/Nailong.app\n'
