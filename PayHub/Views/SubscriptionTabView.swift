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
    @Query(sort: \SubscriptionItem.name) private var subscriptions: [SubscriptionItem]
    @State private var showingAddSheet = false
    @State private var selectedFilter: SubscriptionFilter = .all

    var body: some View {
        NavigationStack {
            Group {
                if subscriptions.isEmpty {
                    SampleDataContentUnavailableView(
                        title: "サブスクがまだありません",
                        systemImage: "repeat.circle",
                        description: "右上の追加ボタンから登録できます。支払い方法や請求スケジュールはあとから設定できます。",
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
                                    VStack(alignment: .leading, spacing: 4) {
                                        ActiveStatusRow(
                                            subscription,
                                            title: subscription.name,
                                            trailingText: subscription.amountWithBillingCycleText
                                        )

                                        if subscription.isActive, let billingStatus = subscription.nextBillingStatus {
                                            BillingScheduleProgressView(
                                                scheduleLabel: "請求日",
                                                status: billingStatus
                                            )
                                        }
                                    }
                                }
                            }
                            .onDelete(perform: deleteSubscriptions)
                        }
                    }
                }
            }
            .navigationTitle("サブスク")
            .floatingBadge {
                if let totalAmountText {
                    FloatingBadge {
                        HStack(spacing: 8) {
                            ActiveStatusIndicator(
                                isActive: true,
                                statusText: "利用中のサブスクのみを集計"
                            )

                            Text("合計 \(totalAmountText)")
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
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("サブスクを追加", systemImage: "plus")
                    }
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
        case .all:
            matchingSubscriptions = subscriptions
        case .monthly:
            matchingSubscriptions = subscriptions.filter { $0.billingCycle == .monthly }
        case .yearly:
            matchingSubscriptions = subscriptions.filter { $0.billingCycle == .yearly }
        }

        return matchingSubscriptions.sortedForDisplay()
    }

    private var totalAmount: Int {
        filteredSubscriptions.filter(\.isActive).reduce(0) { partialResult, subscription in
            partialResult + subscription.amount
        }
    }

    private var totalAmountText: String? {
        guard let billingCycle = selectedFilter.billingCycle else {
            return nil
        }

        return billingCycle.formattedAmount(totalAmount)
    }

    private func addSampleData() {
        SampleDataSeeder.seed(in: modelContext)
    }
}

private enum SubscriptionFilter: String, CaseIterable, Identifiable {
    case all
    case monthly
    case yearly

    var id: Self { self }

    var label: String {
        switch self {
        case .all:
            "すべて"
        case .monthly:
            SubscriptionBillingCycle.monthly.label
        case .yearly:
            SubscriptionBillingCycle.yearly.label
        }
    }

    var emptyTitle: String {
        switch self {
        case .all:
            "サブスクがまだありません"
        case .monthly:
            "月額サブスクがまだありません"
        case .yearly:
            "年額サブスクがまだありません"
        }
    }

    var emptyDescription: String {
        switch self {
        case .all:
            "サブスクを追加するとここに表示されます。"
        case .monthly:
            "月額サブスクを追加するとここに表示されます。"
        case .yearly:
            "年額サブスクを追加するとここに表示されます。"
        }
    }

    var billingCycle: SubscriptionBillingCycle? {
        switch self {
        case .all:
            nil
        case .monthly:
            .monthly
        case .yearly:
            .yearly
        }
    }
}

#Preview {
    SubscriptionTabView()
        .modelContainer(PreviewData.makeModelContainer())
}
