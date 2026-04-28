//
//  ContentView.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            SubscriptionTabView()
                .tabItem {
                    Label("固定費", systemImage: "repeat.circle")
                }

            CardTabView()
                .tabItem {
                    Label("カード", systemImage: "creditcard")
                }

            ElectronicMoneyTabView()
                .tabItem {
                    Label("電子マネー", systemImage: "iphone.gen3")
                }

            BankTabView()
                .tabItem {
                    Label("銀行口座", systemImage: "building.columns")
                }
        }
        .task {
            await NotificationScheduler.shared.rescheduleAll(using: modelContext)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }

            Task {
                await NotificationScheduler.shared.rescheduleAll(using: modelContext)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewData.makeModelContainer())
}
