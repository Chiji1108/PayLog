#!/bin/bash
# App Store 用スクリーンショットを撮影・合成して screenshots/ に保存する。
# 使い方: scripts/screenshots.sh ["シミュレータ名" ...]
set -euo pipefail
cd "$(dirname "$0")/.."

# App Store Connect が受け付けるサイズの端末:
# iPhone 18 Pro は 6.3 インチ（1206×2622）、iPhone Duo は外側の画面（1398×2034）
if [ $# -eq 0 ]; then
    set -- "iPhone 18 Pro" "iPhone Duo"
fi

for DEVICE in "$@"; do
    RAW_DIR="$PWD/screenshots/raw/$DEVICE"      # アプリ画面の素材
    STORE_DIR="$PWD/screenshots/store/$DEVICE"  # コピーと端末フレームを載せた完成画像

    rm -rf "$RAW_DIR" "$STORE_DIR"
    mkdir -p "$RAW_DIR" "$STORE_DIR"

    xcrun simctl bootstatus "$DEVICE" -b >/dev/null
    xcrun simctl status_bar "$DEVICE" override \
        --time "9:41" --batteryState discharging --batteryLevel 100 --wifiBars 3 --cellularBars 4
    trap 'xcrun simctl status_bar "$DEVICE" clear' EXIT

    TEST_RUNNER_SCREENSHOT_DIR="$RAW_DIR" xcodebuild test \
        -scheme PayLog \
        -destination "platform=iOS Simulator,name=$DEVICE" \
        -only-testing:PayLogUITests \
        -quiet

    xcrun simctl status_bar "$DEVICE" clear
    swift scripts/compose-screenshots.swift "$RAW_DIR" "$STORE_DIR"
done
