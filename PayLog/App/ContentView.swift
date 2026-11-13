//
//  ContentView.swift
//  PayLog
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
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

            BankTabView()
                .tabItem {
                    Label("銀行口座", systemImage: "building.columns")
                }

            ElectronicMoneyTabView()
                .tabItem {
                    Label("ウォレット", systemImage: "iphone.gen3")
                }
        }
        .task {
            guard !ProcessInfo.isRunningForXcodePreviews else {
                return
            }

            refreshLifecycleAndNotifications()
        }
        .reviewRequest()
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

            guard !ProcessInfo.isRunningForXcodePreviews else {
                return
            }

            refreshLifecycleAndNotifications()
        }
    }

    private func refreshLifecycleAndNotifications() {
        Task {
            SubscriptionLifecycleUpdater.stopDueCancellations(using: modelContext)
            await NotificationScheduler.shared.rescheduleAll(using: modelContext)
        }
    }

    private var onboardingBinding: Binding<Bool> {
        Binding(
            get: { !hasCompletedOnboarding && !ProcessInfo.isRunningForXcodePreviews },
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
