#!/bin/zsh
# Copies the latest daylume page into the iOS app. Run this after changing ../index.html, then build in Xcode.
set -euo pipefail
cd "$(dirname "$0")"
cp ../index.html Daylume/web/index.html
echo "✓ Daylume/web/index.html updated from ../index.html"
