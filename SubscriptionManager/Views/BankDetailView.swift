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
            if bank.branchName != nil || bank.accountNumber != nil {
                Section("銀行口座") {
                    if let branchName = bank.branchName {
                        LabeledContent("支店名", value: branchName)
                    }

                    if let accountNumber = bank.accountNumber {
                        LabeledContent("口座番号", value: accountNumber)
                    }
                }
            }

            if let notes = bank.trimmedNotes {
                Section("メモ") {
                    Text(notes)
                }
            }

            Section("この口座から引き落とすカード") {
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

            Section("口座振替のサブスク") {
                if sortedSubscriptions.isEmpty {
                    Text("まだサブスクはありません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedSubscriptions) { subscription in
                        NavigationLink {
                            SubscriptionDetailView(subscription: subscription)
                        } label: {
                            ActiveStatusRow(
                                subscription,
                                title: subscription.name,
                                trailingText: subscription.amount.formatted(
                                    .currency(code: "JPY").precision(.fractionLength(0))
                                )
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle(bank.name)
        .activeStatusBadge(bank)
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
        (bank.cards ?? []).sortedForDisplay()
    }

    private var sortedSubscriptions: [SubscriptionItem] {
        (bank.subscriptions ?? []).sortedForDisplay()
    }
}
#Preview("Bank Detail", traits: .sampleData) {
    @Previewable @Query(sort: \Bank.name) var banks: [Bank]

    NavigationStack {
        BankDetailView(bank: banks.first!)
    }
}
