//
//  SubscriptionTabView.swift
//  PayLog
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI
import SwiftData
import TipKit

struct SubscriptionTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        sort: [
            SortDescriptor(\SubscriptionItem.sortOrder),
            SortDescriptor(\SubscriptionItem.createdAt, order: .reverse),
            SortDescriptor(\SubscriptionItem.name)
        ]
    ) private var subscriptions: [SubscriptionItem]
    @State private var showingAddSheet = false
    @State private var selectedFilter: SubscriptionFilter = .all
    @State private var hasCreatedItemInPresentedSheet = false
    @State private var reviewRequestTrigger = 0

    init() {}

    var body: some View {
        NavigationStack {
            Group {
                if subscriptions.isEmpty {
                    SampleDataContentUnavailableView(
                        title: "固定費がまだありません",
                        systemImage: "repeat.circle",
                        description: "カードや銀行口座を登録しておくと、スムーズに追加できます。",
                        shouldConfirmReplacement: shouldConfirmSampleDataReplacement,
                        applySampleData: applySampleData
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
                            if !activeSubscriptions.isEmpty {
                                Section {
                                    if allowsManualReordering {
                                        ForEach(activeSubscriptions) { subscription in
                                            subscriptionNavigationLink(for: subscription)
                                        }
                                        .onDelete(perform: deleteActiveSubscriptions)
                                        .onMove(perform: moveActiveSubscriptions)
                                    } else {
                                        ForEach(activeSubscriptions) { subscription in
                                            subscriptionNavigationLink(for: subscription)
                                        }
                                        .onDelete(perform: deleteActiveSubscriptions)
                                    }
                                } header: {
                                    ActiveStatusSectionHeader(isActive: true)
                                }
                            }

                            if !inactiveSubscriptions.isEmpty {
                                Section {
                                    if allowsManualReordering {
                                        ForEach(inactiveSubscriptions) { subscription in
                                            subscriptionNavigationLink(for: subscription)
                                        }
                                        .onDelete(perform: deleteInactiveSubscriptions)
                                        .onMove(perform: moveInactiveSubscriptions)
                                    } else {
                                        ForEach(inactiveSubscriptions) { subscription in
                                            subscriptionNavigationLink(for: subscription)
                                        }
                                        .onDelete(perform: deleteInactiveSubscriptions)
                                    }
                                } header: {
                                    ActiveStatusSectionHeader(isActive: false)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("固定費")
            .task {
                normalizeSortOrdersIfNeeded()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                        .disabled(!allowsManualReordering)
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Picker("請求サイクル", selection: $selectedFilter) {
                            Text("すべて").tag(SubscriptionFilter.all)

                            ForEach(availableFrequencies) { frequency in
                                Text(frequency.filterLabel).tag(SubscriptionFilter.frequency(frequency))
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                    .accessibilityLabel("請求サイクルで絞り込む")

                    NavigationLink {
                        SubscriptionInsightsView()
                    } label: {
                        Label("分析を見る", systemImage: "chart.bar.xaxis")
                    }

                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("固定費を追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet, onDismiss: handleAddSheetDismiss) {
                SubscriptionEditorView(subscription: nil, onDelete: nil, onCreate: {
                    hasCreatedItemInPresentedSheet = true
                })
            }
            .onChange(of: availableFrequencies) { _, newValue in
                if case let .frequency(frequency) = selectedFilter, !newValue.contains(frequency) {
                    selectedFilter = .all
                }
            }
            .onChange(of: subscriptions.count) { oldValue, newValue in
                guard oldValue == 0, newValue > 0 else {
                    return
                }

                Task {
                    await SwipeToDeleteTip.listReceivedFirstItem.donate()
                }
            }
        }
        .reviewRequestAfterCreation(trigger: reviewRequestTrigger)
    }

    private func deleteActiveSubscriptions(offsets: IndexSet) {
        let remainingSubscriptions = activeSubscriptions.enumerated()
            .filter { !offsets.contains($0.offset) }
            .map(\.element)

        for index in offsets {
            modelContext.delete(activeSubscriptions[index])
        }

        remainingSubscriptions.normalizeSortOrders()
        saveModelContext()
    }

    private func deleteInactiveSubscriptions(offsets: IndexSet) {
        let remainingSubscriptions = inactiveSubscriptions.enumerated()
            .filter { !offsets.contains($0.offset) }
            .map(\.element)

        for index in offsets {
            modelContext.delete(inactiveSubscriptions[index])
        }

        remainingSubscriptions.normalizeSortOrders()
        saveModelContext()
    }

    private func moveActiveSubscriptions(from source: IndexSet, to destination: Int) {
        var reorderedSubscriptions = activeSubscriptions
        reorderedSubscriptions.move(fromOffsets: source, toOffset: destination)
        reorderedSubscriptions.normalizeSortOrders()
        saveModelContext()
    }

    private func moveInactiveSubscriptions(from source: IndexSet, to destination: Int) {
        var reorderedSubscriptions = inactiveSubscriptions
        reorderedSubscriptions.move(fromOffsets: source, toOffset: destination)
        reorderedSubscriptions.normalizeSortOrders()
        saveModelContext()
    }

    private var filteredSubscriptions: [SubscriptionItem] {
        let sortedSubscriptions = subscriptions.sortedForDisplay()

        return switch selectedFilter {
        case .all:
            sortedSubscriptions
        case let .frequency(frequency):
            sortedSubscriptions.filter { $0.billingFrequency == frequency }
        }
    }

    private var availableFrequencies: [SubscriptionBillingFrequency] {
        Array(Set(subscriptions.map(\.billingFrequency))).sorted()
    }

    private var activeSubscriptions: [SubscriptionItem] {
        filteredSubscriptions.filter(\.isActive)
    }

    private var inactiveSubscriptions: [SubscriptionItem] {
        filteredSubscriptions.filter { !$0.isActive }
    }

    private var allowsManualReordering: Bool {
        selectedFilter == .all
    }

    private var firstFilteredSubscriptionID: PersistentIdentifier? {
        filteredSubscriptions.first?.persistentModelID
    }

    @ViewBuilder
    private func subscriptionNavigationLink(for subscription: SubscriptionItem) -> some View {
        NavigationLink {
            SubscriptionDetailView(subscription: subscription)
        } label: {
            SubscriptionRow(subscription: subscription)
        }
        .swipeToDeleteTip(isPresented: subscription.persistentModelID == firstFilteredSubscriptionID)
    }

    private func shouldConfirmSampleDataReplacement() -> Bool {
        SampleDataSeeder.hasAnyData(in: modelContext)
    }

    private func applySampleData() {
        SampleDataSeeder.replaceAllWithSampleData(in: modelContext)
    }

    private func handleAddSheetDismiss() {
        guard hasCreatedItemInPresentedSheet else {
            return
        }

        hasCreatedItemInPresentedSheet = false
        reviewRequestTrigger += 1
    }

    private func normalizeSortOrdersIfNeeded() {
        let didChange = activeSubscriptions.normalizeSortOrders()
            || inactiveSubscriptions.normalizeSortOrders()

        guard didChange else {
            return
        }

        saveModelContext()
    }

    private func saveModelContext() {
        try? modelContext.save()
    }
}

private enum SubscriptionFilter: Hashable, Identifiable {
    case all
    case frequency(SubscriptionBillingFrequency)

    var id: String {
        switch self {
        case .all:
            "all"
        case let .frequency(frequency):
            frequency.id
        }
    }

    var frequency: SubscriptionBillingFrequency? {
        switch self {
        case .all:
            nil
        case let .frequency(frequency):
            frequency
        }
    }

    var emptyTitle: String {
        switch self {
        case .all:
            "固定費がまだありません"
        case let .frequency(frequency):
            "\(frequency.filterLabel)の固定費がまだありません"
        }
    }

    var emptyDescription: String {
        switch self {
        case .all:
            "固定費を追加するとここに表示されます。"
        case let .frequency(frequency):
            "\(frequency.filterLabel)の固定費を追加するとここに表示されます。"
        }
    }
}

private struct SubscriptionRow: View {
    let subscription: SubscriptionItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ActiveStatusRow(
                subscription,
                title: subscription.name,
                trailingText: subscription.amountWithBillingCycleText,
                showIndicator: false
            )

            if subscription.isActive, let billingStatus = subscription.nextBillingStatus {
                BillingScheduleProgressView(
                    scheduleLabel: "請求日",
                    countdownLabel: subscription.billingCountdownLabel,
                    status: billingStatus,
                    isActive: subscription.isActive
                )
            }
        }
    }
}

#Preview {
    SubscriptionTabView()
        .modelContainer(PreviewData.makeModelContainer())
}
