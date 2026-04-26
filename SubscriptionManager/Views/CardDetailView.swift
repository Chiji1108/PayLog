//
//  CardDetailView.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI
import SwiftData

struct CardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var card: Card
    @State private var showingEditSheet = false

    var body: some View {
        List {
            if card.lastFourDigits != nil {
                Section("カード情報") {
                    if let lastFourDigits = card.lastFourDigits {
                        LabeledContent("末尾4桁", value: lastFourDigits)
                    }
                }
            }

            if let notes = card.trimmedNotes {
                Section("備考") {
                    Text(notes)
                }
            }

            Section("引き落とし口座") {
                if let bank = card.bank {
                    NavigationLink {
                        BankDetailView(bank: bank)
                    } label: {
                        ActiveStatusRow(bank, title: bank.name)
                    }
                } else {
                    Text("未設定")
                        .foregroundStyle(.secondary)
                }
            }

            Section("このカードで支払うサブスク") {
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

            Section("このカードに紐づく電子マネー") {
                if sortedElectronicMoneys.isEmpty {
                    Text("まだ電子マネーはありません")
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
        .navigationTitle(card.name)
        .activeStatusBadge(card)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("編集") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            CardEditorView(card: card) {
                dismiss()
            }
        }
    }

    private var sortedSubscriptions: [SubscriptionItem] {
        (card.subscriptions ?? []).sortedForDisplay()
    }

    private var sortedElectronicMoneys: [ElectronicMoney] {
        (card.electronicMoneys ?? []).sortedForDisplay()
    }
}

#Preview("Card Detail", traits: .sampleData) {
    @Previewable @Query(sort: \Card.name) var cards: [Card]

    NavigationStack {
        CardDetailView(card: cards.first!)
    }
}
