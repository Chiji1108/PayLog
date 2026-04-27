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
                        ForEach(displayedCards) { card in
                            NavigationLink {
                                CardDetailView(card: card)
                            } label: {
                                CardRow(card: card)
                            }
                        }
                        .onDelete(perform: deleteCards)
                    }
                }
            }
            .navigationTitle("カード")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
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

    private func deleteCards(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(displayedCards[index])
        }
    }

    private var displayedCards: [Card] {
        cards.sortedForDisplay()
    }

    private func addSampleData() {
        SampleDataSeeder.seed(in: modelContext)
    }
}

private struct CardRow: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ActiveStatusRow(card, title: card.name)

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
