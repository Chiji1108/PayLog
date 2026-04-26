//
//  PayHubApp.swift
//  PayHub
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI
import SwiftData

@main
struct PayHubApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Bank.self,
            Card.self,
            ElectronicMoney.self,
            SubscriptionItem.self,
        ])
    }
}
