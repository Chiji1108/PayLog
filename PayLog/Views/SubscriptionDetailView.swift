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
            Section("固定費") {
                ActiveStatusLabeledContent(item: subscription)
                LabeledContent("金額", value: subscription.amountWithBillingCycleText)
                BillingScheduleProgressView(
                    scheduleLabel: "請求日",
                    countdownLabel: subscription.billingCountdownLabel,
                    status: subscription.nextBillingStatus,
                    isActive: subscription.isActive
                )
                LabeledContent("支払い方法", value: subscription.paymentMethod.label)

                switch subscription.paymentMethod {
                case .card:
                    if let card = subscription.card {
                        ActiveStatusLabeledNavigationRow(
                            "支払いカード",
                            item: card,
                            title: card.name
                        ) {
                            CardDetailView(card: card)
                        }
                    } else {
                        LabeledContent("支払いカード") {
                            Text("未設定")
                        }
                    }
                case .bankAccount:
                    if let bank = subscription.bank {
                        ActiveStatusLabeledNavigationRow(
                            "引き落とし口座",
                            item: bank,
                            title: bank.name
                        ) {
                            BankDetailView(bank: bank)
                        }
                    } else {
                        LabeledContent("引き落とし口座") {
                            Text("未設定")
                        }
                    }
                case .invoice, .onSite, .unspecified:
                    EmptyView()
                }

            }

            Section("メモ") {
                if let notes = subscription.trimmedNotes {
                    Text(notes)
                } else {
                    Text("未設定")
                        .foregroundStyle(.secondary)
                }
            }

        }
        .navigationTitle(subscription.name)
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
