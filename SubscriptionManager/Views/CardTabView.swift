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
    @Query(sort: \Card.name) private var cards: [Card]
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if cards.isEmpty {
                    SampleDataContentUnavailableView(
                        title: "カードがまだありません",
                        systemImage: "creditcard",
                        description: "右上の追加ボタンから登録できます。引き落とし口座はあとから設定できます。",
                        addSampleData: addSampleData
                    )
                } else {
                    List {
                        ForEach(displayedCards) { card in
                            NavigationLink {
                                CardDetailView(card: card)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    ActiveStatusRow(card, title: card.name)

                                    if card.isActive, let withdrawalStatus = card.nextWithdrawalStatus {
                                        BillingScheduleProgressView(
                                            scheduleLabel: "引き落とし日",
                                            status: withdrawalStatus
                                        )
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteCards)
                    }
                }
            }
            .navigationTitle("カード")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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

#Preview {
    CardTabView()
        .modelContainer(PreviewData.makeModelContainer())
}
