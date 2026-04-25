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
                LabeledContent("月額", value: subscription.monthlyAmount.formatted(.currency(code: "JPY").precision(.fractionLength(0))))
                LabeledContent("状態", value: subscription.statusText)
            }

            Section("関連") {
                NavigationLink {
                    CardDetailView(card: subscription.card)
                } label: {
                    LabeledContent("カード", value: subscription.card.name)
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
