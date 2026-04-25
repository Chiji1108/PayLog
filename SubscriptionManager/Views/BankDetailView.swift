//
//  BankDetailView.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI
import SwiftData

struct BankDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var bank: Bank
    @State private var showingEditSheet = false

    var body: some View {
        List {
            Section("基本情報") {
                LabeledContent("状態", value: bank.statusText)
                LabeledContent("カード数", value: "\(bank.cards.count)件")
            }

            Section("紐づくカード") {
                if sortedCards.isEmpty {
                    Text("まだカードはありません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedCards) { card in
                        NavigationLink {
                            CardDetailView(card: card)
                        } label: {
                            HStack {
                                Text(card.name)
                                Spacer()
                                ActiveStatusIndicator(card)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(bank.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("編集") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            BankEditorView(bank: bank) {
                dismiss()
            }
        }
    }

    private var sortedCards: [Card] {
        bank.cards.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
#Preview("Bank Detail", traits: .sampleData) {
    @Previewable @Query(sort: \Bank.name) var banks: [Bank]

    NavigationStack {
        BankDetailView(bank: banks.first!)
    }
}
