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
    @AppStorage(ReviewRequestPolicy.firstLaunchTimestampKey) private var firstLaunchTimestamp = 0.0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

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
            if firstLaunchTimestamp == 0 {
                firstLaunchTimestamp = Date.now.timeIntervalSince1970
            }

            await NotificationScheduler.shared.rescheduleAll(using: modelContext)
        }
        .fullScreenCover(isPresented: onboardingBinding) {
            OnboardingView {
                hasCompletedOnboarding = true
            }
            .interactiveDismissDisabled()
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

    private var onboardingBinding: Binding<Bool> {
        Binding(
            get: { !hasCompletedOnboarding },
            set: { isPresented in
                hasCompletedOnboarding = !isPresented
            }
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewData.makeModelContainer())
}
