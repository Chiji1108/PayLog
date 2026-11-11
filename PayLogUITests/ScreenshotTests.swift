//
//  ScreenshotTests.swift
//  PayLogUITests
//

import XCTest

/// App Store 用スクリーンショットの素材を撮影する。`scripts/screenshots.sh` から実行する。
@MainActor
final class ScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCaptureScreenshots() throws {
        launch(hasCompletedOnboarding: true)

        capture("01-subscriptions")

        row("Netflix").tap()
        capture("02-subscription-detail", highlighting: ["支払い方法", "支払いカード"])

        app.buttons["編集"].tap()
        capture("03-subscription-editor", highlighting: ["通貨", "単位", "毎月"])
        app.buttons["キャンセル"].tap()
        goBack()

        app.buttons["分析を見る"].tap()
        capture("04-subscription-insights")
        goBack()

        app.swipeUp()
        capture("05-subscriptions-inactive", highlighting: ["Spotify", "YouTube Premium", "MUFG Card 年会費"])

        app.tabBars.buttons["カード"].tap()
        row("Olive").tap()
        app.swipeUp()
        capture("06-card-detail", highlighting: ["Netflix", "ChatGPT Plus", "¥5,500"])
        goBack()

        app.buttons["通知設定"].tap()
        turnOn("締日通知をオン")
        turnOn("引き落とし日通知をオン")
        capture("07-card-notifications", highlighting: ["締日通知をオン", "通知タイミング", "通知時刻"])
        goBack()

        app.tabBars.buttons["銀行口座"].tap()
        row("三菱UFJ銀行").tap()
        capture("08-bank-detail", highlighting: ["支店名", "口座番号"])

        app.terminate()
        launch(hasCompletedOnboarding: false)
        capture("09-onboarding")
    }

    private func launch(hasCompletedOnboarding: Bool) {
        app = XCUIApplication()
        app.launchArguments = [
            "-screenshots",
            "-hasCompletedOnboarding", hasCompletedOnboarding ? "YES" : "NO",
            "-AppleLanguages", "(ja)",
            "-AppleLocale", "ja_JP",
        ]
        app.launch()
    }

    private func row(_ name: String) -> XCUIElement {
        let element = app.collectionViews.buttons
            .matching(NSPredicate(format: "label CONTAINS %@", name))
            .firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: 5), "\(name) の行が見つからない")
        return element
    }

    private func goBack() {
        app.navigationBars.buttons.firstMatch.tap()
    }

    /// 通知のスイッチをオンにする。初回だけ出る通知の許可ダイアログは許可する。
    private func turnOn(_ label: String) {
        let toggle = app.switches[label]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5), "\(label) のスイッチが見つからない")
        guard toggle.value as? String == "0" else { return }
        toggle.switches.firstMatch.tap()

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowButton = springboard.alerts.buttons.element(boundBy: 1)
        if allowButton.waitForExistence(timeout: 2) {
            allowButton.tap()
        }
    }

    /// 環境変数 SCREENSHOT_DIR があればそこへ PNG を書き出し、なければテスト結果に添付する。
    /// `highlighting` に行の文言を渡すと、それらの行を囲む範囲（画面に対する割合）を
    /// 同名の JSON に書き出す。完成画像では、その範囲が拡大して重ねられる。
    private func capture(_ name: String, highlighting rows: [String] = []) {
        // 画面遷移のアニメーションが終わるのを待つ
        Thread.sleep(forTimeInterval: 1)
        let screenshot = XCUIScreen.main.screenshot()

        guard let directory = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] else {
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
            return
        }

        let base = URL(fileURLWithPath: directory).appendingPathComponent(name)
        XCTAssertNoThrow(try screenshot.pngRepresentation.write(to: base.appendingPathExtension("png")))

        if !rows.isEmpty {
            let screen = app.frame
            let frame = rows.map(cellFrame).reduce(CGRect.null) { $0.union($1) }
            let highlight = CGRect(
                x: frame.minX / screen.width,
                y: frame.minY / screen.height,
                width: frame.width / screen.width,
                height: frame.height / screen.height
            )
            XCTAssertNoThrow(try JSONEncoder().encode(highlight).write(to: base.appendingPathExtension("json")))
        }
    }

    /// `text` を含むリストの行の位置
    private func cellFrame(_ text: String) -> CGRect {
        let cell = app.cells
            .containing(NSPredicate(format: "label CONTAINS %@", text))
            .firstMatch
        XCTAssertTrue(cell.exists, "\(text) の行が見つからない")
        return cell.frame
    }
}
