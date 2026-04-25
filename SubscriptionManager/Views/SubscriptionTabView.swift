//
//  SubscriptionTabView.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI
import SwiftData

struct SubscriptionTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Card.name) private var cards: [Card]
    @Query(sort: \SubscriptionItem.name) private var subscriptions: [SubscriptionItem]
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if cards.isEmpty {
                    ContentUnavailableView(
                        "先にカードを登録してください",
                        systemImage: "creditcard",
                        description: Text("サブスクはカードに紐付きます。銀行、カードの順で登録してください。")
                    )
                } else if subscriptions.isEmpty {
                    ContentUnavailableView(
                        "サブスクがまだありません",
                        systemImage: "repeat.circle",
                        description: Text("右上の追加ボタンから登録できます。")
                    )
                } else {
                    List {
                        ForEach(subscriptions) { subscription in
                            NavigationLink {
                                SubscriptionDetailView(subscription: subscription)
                            } label: {
                                SubscriptionRow(subscription: subscription)
                            }
                        }
                        .onDelete(perform: deleteSubscriptions)
                    }
                }
            }
            .navigationTitle("サブスク")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("サブスクを追加", systemImage: "plus")
                    }
                    .disabled(cards.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                SubscriptionEditorView()
            }
        }
    }

    private func deleteSubscriptions(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(subscriptions[index])
        }
    }
}

private struct SubscriptionRow: View {
    @Bindable var subscription: SubscriptionItem

    var body: some View {
        HStack {
            ActiveStatusIndicator(subscription)

            Text(subscription.name)
                .font(.headline)

            Spacer()

            Text(
                subscription.monthlyAmount.formatted(
                    .currency(code: "JPY").precision(.fractionLength(0))
                )
            )
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SubscriptionTabView()
        .modelContainer(PreviewData.makeModelContainer())
}
