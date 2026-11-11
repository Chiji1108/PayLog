#!/bin/bash
# App Store 用スクリーンショットを撮影・合成して screenshots/ に保存する。
# 使い方: scripts/screenshots.sh ["シミュレータ名"]
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE="${1:-iPhone 18 Pro Max}"
RAW_DIR="$PWD/screenshots/raw"      # アプリ画面の素材
STORE_DIR="$PWD/screenshots/store"  # コピーと端末フレームを載せた完成画像

mkdir -p "$RAW_DIR" "$STORE_DIR"
rm -f "$RAW_DIR"/*.png "$STORE_DIR"/*.png

xcrun simctl bootstatus "$DEVICE" -b >/dev/null
xcrun simctl status_bar "$DEVICE" override \
    --time "9:41" --batteryState discharging --batteryLevel 100 --wifiBars 3 --cellularBars 4
trap 'xcrun simctl status_bar "$DEVICE" clear' EXIT

TEST_RUNNER_SCREENSHOT_DIR="$RAW_DIR" xcodebuild test \
    -scheme PayLog \
    -destination "platform=iOS Simulator,name=$DEVICE" \
    -only-testing:PayLogUITests \
    -quiet

swift scripts/compose-screenshots.swift "$RAW_DIR" "$STORE_DIR"
