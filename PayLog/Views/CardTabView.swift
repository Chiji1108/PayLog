//
//  CardTabView.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI
import SwiftData

struct CardTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var cards: [Card]
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if cards.isEmpty {
                    SampleDataContentUnavailableView(
                        title: "カードがまだありません",
                        systemImage: "creditcard",
                        description: "銀行口座を登録しておくと、スムーズに追加できます。",
                        addSampleData: addSampleData
                    )
                } else {
                    List {
                        if !activeCards.isEmpty {
                            Section {
                                ForEach(activeCards) { card in
                                    NavigationLink {
                                        CardDetailView(card: card)
                                    } label: {
                                        CardRow(card: card)
                                    }
                                }
                                .onDelete(perform: deleteActiveCards)
                            } header: {
                                ActiveStatusSectionHeader(isActive: true)
                            }
                        }

                        if !inactiveCards.isEmpty {
                            Section {
                                ForEach(inactiveCards) { card in
                                    NavigationLink {
                                        CardDetailView(card: card)
                                    } label: {
                                        CardRow(card: card)
                                    }
                                }
                                .onDelete(perform: deleteInactiveCards)
                            } header: {
                                ActiveStatusSectionHeader(isActive: false)
                            }
                        }
                    }
                }
            }
            .navigationTitle("カード")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink {
                        CardNotificationSettingsView()
                    } label: {
                        Label("通知設定", systemImage: "bell")
                    }

                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("カードを追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                CardEditorView()
            }
        }
    }

    private func deleteActiveCards(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(activeCards[index])
        }

        rescheduleNotifications()
    }

    private func deleteInactiveCards(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(inactiveCards[index])
        }

        rescheduleNotifications()
    }

    private var displayedCards: [Card] {
        cards.sortedForDisplay()
    }

    private var activeCards: [Card] {
        displayedCards.filter(\.isActive)
    }

    private var inactiveCards: [Card] {
        displayedCards.filter { !$0.isActive }
    }

    private func addSampleData() {
        SampleDataSeeder.seed(in: modelContext)
        rescheduleNotifications()
    }

    private func rescheduleNotifications() {
        Task {
            try? modelContext.save()
            await NotificationScheduler.shared.rescheduleAll(using: modelContext)
        }
    }
}

private struct CardRow: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ActiveStatusRow(card, title: card.name, showIndicator: false)

            if card.isActive, let closingStatus = card.nextClosingStatus {
                BillingScheduleProgressView(
                    scheduleLabel: "締日",
                    countdownLabel: "締日",
                    status: closingStatus,
                    isActive: card.isActive
                )
            }

            if card.isActive, let withdrawalStatus = card.nextWithdrawalStatus {
                BillingScheduleProgressView(
                    scheduleLabel: "引き落とし日",
                    countdownLabel: "引き落とし",
                    status: withdrawalStatus,
                    isActive: card.isActive
                )
            }
        }
    }
}

#Preview {
    CardTabView()
        .modelContainer(PreviewData.makeModelContainer())
}
