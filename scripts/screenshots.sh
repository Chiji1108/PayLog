#!/bin/bash
# App Store 用スクリーンショットの素材を撮影して screenshots/ に保存する。
# 使い方: scripts/screenshots.sh ["シミュレータ名"]
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE="${1:-iPhone 18 Pro Max}"
OUTPUT_DIR="$PWD/screenshots"

mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR"/*.png

xcrun simctl boot "$DEVICE" 2>/dev/null || true
xcrun simctl status_bar "$DEVICE" override \
    --time "9:41" --batteryState discharging --batteryLevel 100 --wifiBars 3 --cellularBars 4
trap 'xcrun simctl status_bar "$DEVICE" clear' EXIT

TEST_RUNNER_SCREENSHOT_DIR="$OUTPUT_DIR" xcodebuild test \
    -scheme PayLog \
    -destination "platform=iOS Simulator,name=$DEVICE" \
    -only-testing:PayLogUITests \
    -quiet

echo "保存先: $OUTPUT_DIR"
ls "$OUTPUT_DIR"
