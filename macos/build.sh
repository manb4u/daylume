#!/bin/zsh
# Builds daylume.app (universal: Apple Silicon + Intel) and dist/daylume.dmg from ../index.html.
set -euo pipefail
cd "$(dirname "$0")"
ROOT=$(cd .. && pwd); OUT="$ROOT/dist"; BUILD="$OUT/build"; APP="$BUILD/daylume.app"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
rm -rf "$BUILD"; mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/web" "$OUT"

echo "› compiling (arm64 + x86_64)"
for arch in arm64 x86_64; do
  swiftc -O -swift-version 5 -target "$arch-apple-macos13.0" -sdk "$(xcrun --show-sdk-path)" \
    -framework Cocoa -framework WebKit main.swift -o "$BUILD/daylume-$arch"
done
lipo -create "$BUILD/daylume-arm64" "$BUILD/daylume-x86_64" -output "$APP/Contents/MacOS/daylume"
rm "$BUILD"/daylume-arm64 "$BUILD"/daylume-x86_64

echo "› bundling"
cp Info.plist "$APP/Contents/Info.plist"
cp "$ROOT/index.html" "$APP/Contents/Resources/web/index.html"

echo "› icon"
ICONSET="$BUILD/AppIcon.iconset"; mkdir -p "$ICONSET"
"$CHROME" --headless=new --disable-gpu --hide-scrollbars --default-background-color=00000000 \
  --window-size=1024,1024 --screenshot="$BUILD/icon-1024.png" "file://$PWD/icon.html" >/dev/null 2>&1
for s in 16 32 128 256 512; do
  sips -z $s $s "$BUILD/icon-1024.png" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) "$BUILD/icon-1024.png" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

echo "› signing (ad hoc)"
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"

if [[ "${1:-}" != "--no-test" ]]; then
  echo "› self-test"
  "$APP/Contents/MacOS/daylume" --selftest | grep SELFTEST
fi

echo "› disk image"
STAGE="$BUILD/dmg"; mkdir -p "$STAGE"; cp -R "$APP" "$STAGE/"; ln -s /Applications "$STAGE/Applications"
rm -f "$OUT/daylume.dmg"
hdiutil create -volname "daylume" -srcfolder "$STAGE" -ov -format UDZO "$OUT/daylume.dmg" >/dev/null
echo "✓ $OUT/daylume.dmg ($(du -h "$OUT/daylume.dmg" | cut -f1))"
