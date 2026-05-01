//
//  CardTabView.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI
import SwiftData
import TipKit

struct CardTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var cards: [Card]
    @State private var showingAddSheet = false
    @State private var hasCreatedItemInPresentedSheet = false
    @State private var reviewRequestTrigger = 0

    var body: some View {
        NavigationStack {
            Group {
                if cards.isEmpty {
                    SampleDataContentUnavailableView(
                        title: "カードがまだありません",
                        systemImage: "creditcard",
                        description: "銀行口座を登録しておくと、スムーズに追加できます。",
                        shouldConfirmReplacement: shouldConfirmSampleDataReplacement,
                        applySampleData: applySampleData
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
                                    .swipeToDeleteTip(isPresented: card.id == displayedCards.first?.id)
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
                                    .swipeToDeleteTip(isPresented: card.id == displayedCards.first?.id)
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
            .sheet(isPresented: $showingAddSheet, onDismiss: handleAddSheetDismiss) {
                CardEditorView(card: nil, onDelete: nil, onCreate: {
                    hasCreatedItemInPresentedSheet = true
                })
            }
            .onChange(of: cards.count) { oldValue, newValue in
                guard oldValue == 0, newValue > 0 else {
                    return
                }

                Task {
                    await SwipeToDeleteTip.listReceivedFirstItem.donate()
                }
            }
        }
        .reviewRequestAfterCreation(trigger: reviewRequestTrigger)
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

    private func shouldConfirmSampleDataReplacement() -> Bool {
        SampleDataSeeder.hasAnyData(in: modelContext)
    }

    private func applySampleData() {
        SampleDataSeeder.replaceAllWithSampleData(in: modelContext)
        rescheduleNotifications()
    }

    private func rescheduleNotifications() {
        Task {
            try? modelContext.save()
            await NotificationScheduler.shared.rescheduleAll(using: modelContext)
        }
    }

    private func handleAddSheetDismiss() {
        guard hasCreatedItemInPresentedSheet else {
            return
        }

        hasCreatedItemInPresentedSheet = false
        reviewRequestTrigger += 1
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
