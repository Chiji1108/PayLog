#!/bin/bash
# App Store 用スクリーンショットを撮影・合成して screenshots/ に保存する。
# 使い方: scripts/screenshots.sh ["シミュレータ名" ...]
set -euo pipefail
cd "$(dirname "$0")/.."

# App Store Connect が受け付けるサイズの端末:
# iPhone 18 Pro は 6.3 インチ（1206×2622）、iPhone Duo は外側の画面（1398×2034）、
# iPad Pro 13-inch (M5) は 13 インチ（横向きで 2752×2064）
# iPhone Duo は閉じた状態で撮る（開いていると、消灯した外側の画面が写る）
if [ $# -eq 0 ]; then
    set -- "iPhone 18 Pro" "iPhone Duo" "iPad Pro 13-inch (M5)"
fi

RAW_ROOT="$PWD/screenshots/raw"      # アプリ画面の素材（端末ごと）
STORE_ROOT="$PWD/screenshots/store"  # コピーと端末フレームを載せた完成画像（端末ごと）

for DEVICE in "$@"; do
    RAW_DIR="$RAW_ROOT/$DEVICE"
    rm -rf "$RAW_DIR"
    mkdir -p "$RAW_DIR"

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
done

# 完成画像は、素材のある端末すべてについて作り直す（iPad の 1 枚と、ヘッダ用・リンク用の画像は、複数の端末の素材を使う）
rm -rf "$STORE_ROOT"
swift scripts/compose-screenshots.swift "$RAW_ROOT" "$STORE_ROOT"
