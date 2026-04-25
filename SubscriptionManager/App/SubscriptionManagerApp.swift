//
//  SubscriptionManagerApp.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI
import SwiftData

@main
struct SubscriptionManagerApp: App {
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
