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
    init() {
        do {
            try Tips.configure()
        } catch {
            assertionFailure("Failed to configure TipKit: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Bank.self,
            Card.self,
            ElectronicMoney.self,
            SubscriptionItem.self,
        ], isUndoEnabled: true)
    }
}
