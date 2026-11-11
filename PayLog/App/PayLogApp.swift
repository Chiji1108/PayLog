//
//  PayLogApp.swift
//  PayLog
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI
import SwiftData
import TipKit

@main
struct PayLogApp: App {
    /// App Store 用スクリーンショットの撮影時（UI テストが `-screenshots` 付きで起動）だけ、
    /// サンプルデータ入りのメモリ内ストアに差し替える。
    private let screenshotContainer: ModelContainer?

    init() {
        let isTakingScreenshots = ProcessInfo.processInfo.arguments.contains("-screenshots")
        screenshotContainer = isTakingScreenshots ? PreviewData.makeModelContainer() : nil

        do {
            if isTakingScreenshots {
                Tips.hideAllTipsForTesting()
            }
            try Tips.configure()
        } catch {
            assertionFailure("Failed to configure TipKit: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if let screenshotContainer {
                ContentView()
                    .modelContainer(screenshotContainer)
            } else {
                ContentView()
            }
        }
        .modelContainer(for: [
            Bank.self,
            Card.self,
            ElectronicMoney.self,
            SubscriptionItem.self,
        ], isUndoEnabled: true)
    }
}
