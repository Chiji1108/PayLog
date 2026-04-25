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
            DetailStatusSection(bank)

            if bank.branchName != nil || bank.accountNumber != nil {
                Section("口座情報") {
                    if let branchName = bank.branchName {
                        LabeledContent("支店名", value: branchName)
                    }

                    if let accountNumber = bank.accountNumber {
                        LabeledContent("口座番号", value: accountNumber)
                    }
                }
            }

            if let notes = bank.trimmedNotes {
                Section("備考") {
                    Text(notes)
                }
            }

            Section("引き落としカード") {
                if sortedCards.isEmpty {
                    Text("まだカードはありません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedCards) { card in
                        NavigationLink {
                            CardDetailView(card: card)
                        } label: {
                            ActiveStatusRow(card, title: card.name)
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
