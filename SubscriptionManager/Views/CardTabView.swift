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
    @Query(sort: \Bank.name) private var banks: [Bank]
    @Query(sort: \Card.name) private var cards: [Card]
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if banks.isEmpty {
                    SampleDataContentUnavailableView(
                        title: "先に銀行を登録してください",
                        systemImage: "building.columns",
                        description: "カードは銀行に紐付きます。まず銀行を追加してください。",
                        addSampleData: addSampleData
                    )
                } else if cards.isEmpty {
                    SampleDataContentUnavailableView(
                        title: "カードがまだありません",
                        systemImage: "creditcard",
                        description: "右上の追加ボタンから登録できます。",
                        addSampleData: addSampleData
                    )
                } else {
                    List {
                        ForEach(displayedCards) { card in
                            NavigationLink {
                                CardDetailView(card: card)
                            } label: {
                                ActiveStatusRow(card, title: card.name)
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
                    .disabled(banks.isEmpty)
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
