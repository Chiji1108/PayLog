//
//  SubscriptionDetailView.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI
import SwiftData

struct SubscriptionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var subscription: SubscriptionItem
    @State private var showingEditSheet = false

    var body: some View {
        List {
            Section("基本情報") {
                LabeledContent("請求サイクル", value: subscription.billingCycle.label)
                LabeledContent("金額", value: subscription.amount.formatted(.currency(code: "JPY").precision(.fractionLength(0))))
            }

            if let notes = subscription.trimmedNotes {
                Section("備考") {
                    Text(notes)
                }
            }

            Section("支払い方法") {
                LabeledContent("種別", value: subscription.paymentMethod.label)

                switch subscription.paymentMethod {
                case .card:
                    if let card = subscription.card {
                        NavigationLink {
                            CardDetailView(card: card)
                        } label: {
                            ActiveStatusRow(card, title: card.name)
                        }
                    } else {
                        Text("カード未設定")
                            .foregroundStyle(.secondary)
                    }
                case .bankAccount:
                    if let bank = subscription.bank {
                        NavigationLink {
                            BankDetailView(bank: bank)
                        } label: {
                            ActiveStatusRow(bank, title: bank.name)
                        }
                    } else {
                        Text("銀行口座未設定")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(subscription.name)
        .activeStatusBadge(subscription)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("編集") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            SubscriptionEditorView(subscription: subscription) {
                dismiss()
            }
        }
    }
}

#Preview("Subscription Detail", traits: .sampleData) {
    @Previewable @Query(sort: \SubscriptionItem.name) var subscriptions: [SubscriptionItem]

    NavigationStack {
        SubscriptionDetailView(subscription: subscriptions.first!)
    }
}
