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
    @Query(
        sort: [
            SortDescriptor(\Card.sortOrder),
            SortDescriptor(\Card.createdAt, order: .reverse),
            SortDescriptor(\Card.name)
        ]
    ) private var cards: [Card]
    @State private var showingAddSheet = false
    @State private var hasCreatedItemInPresentedSheet = false
    @State private var reviewRequestTrigger = 0

    init() {}

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
                                .onMove(perform: moveActiveCards)
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
                                .onMove(perform: moveInactiveCards)
                            } header: {
                                ActiveStatusSectionHeader(isActive: false)
                            }
                        }
                    }
                }
            }
            .navigationTitle("カード")
            .task {
                normalizeSortOrdersIfNeeded()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }

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
        let remainingCards = activeCards.enumerated()
            .filter { !offsets.contains($0.offset) }
            .map(\.element)

        for index in offsets {
            modelContext.delete(activeCards[index])
        }

        remainingCards.normalizeSortOrders()
        saveModelContext()
        rescheduleNotifications()
    }

    private func deleteInactiveCards(offsets: IndexSet) {
        let remainingCards = inactiveCards.enumerated()
            .filter { !offsets.contains($0.offset) }
            .map(\.element)

        for index in offsets {
            modelContext.delete(inactiveCards[index])
        }

        remainingCards.normalizeSortOrders()
        saveModelContext()
        rescheduleNotifications()
    }

    private func moveActiveCards(from source: IndexSet, to destination: Int) {
        var reorderedCards = activeCards
        reorderedCards.move(fromOffsets: source, toOffset: destination)
        reorderedCards.normalizeSortOrders()
        saveModelContext()
    }

    private func moveInactiveCards(from source: IndexSet, to destination: Int) {
        var reorderedCards = inactiveCards
        reorderedCards.move(fromOffsets: source, toOffset: destination)
        reorderedCards.normalizeSortOrders()
        saveModelContext()
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

    private func normalizeSortOrdersIfNeeded() {
        let didChange = activeCards.normalizeSortOrders() || inactiveCards.normalizeSortOrders()

        guard didChange else {
            return
        }

        saveModelContext()
    }

    private func saveModelContext() {
        try? modelContext.save()
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
