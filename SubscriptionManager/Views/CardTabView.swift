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
                    ContentUnavailableView(
                        "先に銀行を登録してください",
                        systemImage: "building.columns",
                        description: Text("カードは銀行に紐付きます。まず銀行を追加してください。")
                    )
                } else if cards.isEmpty {
                    ContentUnavailableView(
                        "カードがまだありません",
                        systemImage: "creditcard",
                        description: Text("右上の追加ボタンから登録できます。")
                    )
                } else {
                    List {
                        ForEach(cards) { card in
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
            modelContext.delete(cards[index])
        }
    }
}

private struct CardRow: View {
    @Bindable var card: Card

    var body: some View {
        HStack {
            ActiveStatusIndicator(card)

            Text(card.name)
                .font(.headline)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CardTabView()
        .modelContainer(PreviewData.makeModelContainer())
}
