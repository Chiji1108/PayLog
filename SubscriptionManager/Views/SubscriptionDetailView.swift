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
            DetailStatusSection(subscription)

            Section("基本情報") {
                LabeledContent("請求サイクル", value: subscription.billingCycle.label)
                LabeledContent("金額", value: subscription.amount.formatted(.currency(code: "JPY").precision(.fractionLength(0))))
            }

            if let notes = subscription.trimmedNotes {
                Section("備考") {
                    Text(notes)
                }
            }

            Section("支払いカード") {
                NavigationLink {
                    CardDetailView(card: subscription.card)
                } label: {
                    ActiveStatusRow(subscription.card, title: subscription.card.name)
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
