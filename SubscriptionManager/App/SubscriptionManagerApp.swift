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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Bank.self,
            Card.self,
            ElectronicMoney.self,
            SubscriptionItem.self,
        ])
        let modelConfiguration = ModelConfiguration(
            "SubscriptionManagerData",
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
