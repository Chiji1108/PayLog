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
    @State private var selectedFilter: SubscriptionFilter = .monthly

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
                        if filteredSubscriptions.isEmpty {
                            Section {
                                ContentUnavailableView(
                                    selectedFilter.emptyTitle,
                                    systemImage: "repeat.circle",
                                    description: Text(selectedFilter.emptyDescription)
                                )
                            }
                        } else {
                            ForEach(filteredSubscriptions) { subscription in
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
                            .onDelete(perform: deleteSubscriptions)
                        }
                    }
                }
            }
            .navigationTitle("サブスク")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("請求サイクル", selection: $selectedFilter) {
                        ForEach(SubscriptionFilter.allCases) { filter in
                            Text(filter.label).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }

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
            modelContext.delete(filteredSubscriptions[index])
        }
    }

    private var filteredSubscriptions: [SubscriptionItem] {
        let matchingSubscriptions: [SubscriptionItem]

        switch selectedFilter {
        case .monthly:
            matchingSubscriptions = subscriptions.filter { $0.billingCycle == .monthly }
        case .yearly:
            matchingSubscriptions = subscriptions.filter { $0.billingCycle == .yearly }
        }

        return matchingSubscriptions.sortedForDisplay()
    }
}

private enum SubscriptionFilter: String, CaseIterable, Identifiable {
    case monthly
    case yearly

    var id: Self { self }

    var label: String {
        switch self {
        case .monthly:
            "月額"
        case .yearly:
            "年額"
        }
    }

    var emptyTitle: String {
        switch self {
        case .monthly:
            "月額サブスクがまだありません"
        case .yearly:
            "年額サブスクがまだありません"
        }
    }

    var emptyDescription: String {
        switch self {
        case .monthly:
            "月額サブスクを追加するとここに表示されます。"
        case .yearly:
            "年額サブスクを追加するとここに表示されます。"
        }
    }
}

#Preview {
    SubscriptionTabView()
        .modelContainer(PreviewData.makeModelContainer())
}
