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
            Section("基本情報") {
                LabeledContent("状態", value: card.statusText)
            }

            Section("関連") {
                NavigationLink {
                    BankDetailView(bank: card.bank)
                } label: {
                    LabeledContent("銀行", value: card.bank.name)
                }
            }

            Section("紐づくサブスク") {
                if sortedSubscriptions.isEmpty {
                    Text("まだサブスクはありません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedSubscriptions) { subscription in
                        NavigationLink {
                            SubscriptionDetailView(subscription: subscription)
                        } label: {
                            HStack {
                                Text(subscription.name)
                                Spacer()
                                Text(subscription.monthlyAmount.formatted(.currency(code: "JPY").precision(.fractionLength(0))))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("紐づく電子マネー") {
                if sortedElectronicMoneys.isEmpty {
                    Text("まだ電子マネーはありません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedElectronicMoneys) { electronicMoney in
                        NavigationLink {
                            ElectronicMoneyDetailView(electronicMoney: electronicMoney)
                        } label: {
                            HStack {
                                Text(electronicMoney.name)
                                Spacer()
                                ActiveStatusIndicator(electronicMoney)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(card.name)
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
        card.subscriptions.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private var sortedElectronicMoneys: [ElectronicMoney] {
        card.electronicMoneys.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}

#Preview("Card Detail", traits: .sampleData) {
    @Previewable @Query(sort: \Card.name) var cards: [Card]

    NavigationStack {
        CardDetailView(card: cards.first!)
    }
}
