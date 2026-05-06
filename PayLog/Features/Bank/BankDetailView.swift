//
//  BankDetailView.swift
//  PayLog
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
            Section("銀行口座") {
                ActiveStatusLabeledContent(item: bank)

                if let branchName = bank.branchName {
                    LabeledContent("支店名", value: branchName)
                } else {
                    LabeledContent("支店名") {
                        Text("未設定")
                    }
                }

                if let accountNumber = bank.accountNumber {
                    LabeledContent("口座番号", value: accountNumber)
                } else {
                    LabeledContent("口座番号") {
                        Text("未設定")
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

            Section("口座振替の固定費") {
                if sortedSubscriptions.isEmpty {
                    Text("まだ固定費はありません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedSubscriptions) { subscription in
                        NavigationLink {
                            SubscriptionDetailView(subscription: subscription)
                        } label: {
                            ActiveStatusRow(
                                subscription,
                                title: subscription.name,
                                trailingText: subscription.amountWithBillingCycleText
                            )
                        }
                    }
                }
            }

            Section("この口座を入金元にするウォレット") {
                if sortedElectronicMoneys.isEmpty {
                    Text("まだウォレットはありません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedElectronicMoneys) { electronicMoney in
                        NavigationLink {
                            ElectronicMoneyDetailView(electronicMoney: electronicMoney)
                        } label: {
                            ActiveStatusRow(electronicMoney, title: electronicMoney.name)
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
            BankEditorView(bank: bank, onCreate: {
                dismiss()
            })
        }
    }

    private var sortedCards: [Card] {
        (bank.cards ?? []).sortedForDisplay()
    }

    private var sortedSubscriptions: [SubscriptionItem] {
        (bank.subscriptions ?? []).sortedForDisplay()
    }

    private var sortedElectronicMoneys: [ElectronicMoney] {
        (bank.electronicMoneys ?? [])
            .filter { $0.fundingSource == .bankAccount }
            .sortedForDisplay()
    }
}
#Preview("Bank Detail", traits: .sampleData) {
    @Previewable @Query(sort: \Bank.name) var banks: [Bank]

    NavigationStack {
        BankDetailView(bank: banks.first!)
    }
}
