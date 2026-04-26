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
            Section("サブスク") {
                LabeledContent("金額", value: subscription.amountWithBillingCycleText)

                switch subscription.paymentMethod {
                case .card:
                    if let card = subscription.card {
                        ActiveStatusLabeledNavigationRow(
                            "カード支払い",
                            item: card,
                            title: card.name
                        ) {
                            CardDetailView(card: card)
                        }
                    } else {
                        LabeledContent("カード支払い", value: "未設定")
                            .foregroundStyle(.secondary)
                    }
                case .bankAccount:
                    if let bank = subscription.bank {
                        ActiveStatusLabeledNavigationRow(
                            "口座振替",
                            item: bank,
                            title: bank.name
                        ) {
                            BankDetailView(bank: bank)
                        }
                    } else {
                        LabeledContent("口座振替", value: "未設定")
                            .foregroundStyle(.secondary)
                    }
                }

                BillingScheduleProgressView(
                    scheduleLabel: "請求日",
                    status: subscription.nextBillingStatus
                )
            }

            if let notes = subscription.trimmedNotes {
                Section("メモ") {
                    Text(notes)
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
