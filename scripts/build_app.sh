#!/bin/bash
set -e

echo "🔨 Building OpenTiming (Release mode)..."
swift build -c release

APP_NAME="OpenTiming.app"
APP_DIR="./build/$APP_NAME"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

echo "📦 Bundling $APP_NAME..."
cp ".build/release/OpenTiming" "$MACOS/OpenTiming"
cp "Info.plist" "$CONTENTS/Info.plist"

echo "✅ App bundle ready at $APP_DIR"
echo "To run: open $APP_DIR"
