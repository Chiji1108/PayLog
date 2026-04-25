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
    @Query(sort: \Bank.name) private var banks: [Bank]
    @Query(sort: \SubscriptionItem.name) private var subscriptions: [SubscriptionItem]
    @State private var showingAddSheet = false
    @State private var selectedFilter: SubscriptionFilter = .monthly

    var body: some View {
        NavigationStack {
            Group {
                if !hasPaymentMethods {
                    SampleDataContentUnavailableView(
                        title: "先に支払い方法を登録してください",
                        systemImage: "wallet.bifold",
                        description: "サブスクはカードまたは銀行口座に紐付きます。先に登録してください。",
                        addSampleData: addSampleData
                    )
                } else if subscriptions.isEmpty {
                    SampleDataContentUnavailableView(
                        title: "サブスクがまだありません",
                        systemImage: "repeat.circle",
                        description: "右上の追加ボタンから登録できます。",
                        addSampleData: addSampleData
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
            .floatingBadge {
                if !filteredSubscriptions.isEmpty {
                    FloatingBadge {
                        HStack(spacing: 8) {
                            Text(selectedFilter.totalLabel)

                            Text(totalAmountText)
                        }
                    }
                }
            }
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
                    .disabled(!hasPaymentMethods)
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                SubscriptionEditorView()
            }
        }
    }

    private var hasPaymentMethods: Bool {
        !cards.isEmpty || !banks.isEmpty
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

    private var totalAmount: Int {
        filteredSubscriptions.reduce(0) { partialResult, subscription in
            partialResult + subscription.amount
        }
    }

    private var totalAmountText: String {
        totalAmount.formatted(.currency(code: "JPY").precision(.fractionLength(0)))
    }

    private func addSampleData() {
        SampleDataSeeder.seed(in: modelContext)
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

    var totalLabel: String {
        switch self {
        case .monthly:
            "月額合計"
        case .yearly:
            "年額合計"
        }
    }
}

#Preview {
    SubscriptionTabView()
        .modelContainer(PreviewData.makeModelContainer())
}
