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
        capture("02-subscription-detail")

        app.buttons["編集"].tap()
        capture("03-subscription-editor")
        app.buttons["キャンセル"].tap()
        goBack()

        app.buttons["分析を見る"].tap()
        capture("04-subscription-insights")
        goBack()

        app.swipeUp()
        capture("05-subscriptions-inactive")

        app.tabBars.buttons["カード"].tap()
        row("Olive").tap()
        capture("06-card-detail")
        goBack()

        app.buttons["通知設定"].tap()
        capture("07-card-notifications")
        goBack()

        app.tabBars.buttons["銀行口座"].tap()
        row("三菱UFJ銀行").tap()
        capture("08-bank-detail")

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

    /// 環境変数 SCREENSHOT_DIR があればそこへ PNG を書き出し、なければテスト結果に添付する。
    private func capture(_ name: String) {
        // 画面遷移のアニメーションが終わるのを待つ
        Thread.sleep(forTimeInterval: 1)
        let screenshot = XCUIScreen.main.screenshot()

        if let directory = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            let url = URL(fileURLWithPath: directory).appendingPathComponent("\(name).png")
            XCTAssertNoThrow(try screenshot.pngRepresentation.write(to: url))
        } else {
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
}
