//
//  BankTabView.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI
import SwiftData
import TipKit

struct BankTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        sort: [
            SortDescriptor(\Bank.sortOrder),
            SortDescriptor(\Bank.createdAt, order: .reverse),
            SortDescriptor(\Bank.name)
        ]
    ) private var banks: [Bank]
    @State private var showingAddSheet = false
    @State private var hasCreatedItemInPresentedSheet = false
    @State private var reviewRequestTrigger = 0

    init() {}

    var body: some View {
        NavigationStack {
            Group {
                if banks.isEmpty {
                    SampleDataContentUnavailableView(
                        title: "銀行口座がまだありません",
                        systemImage: "building.columns",
                        description: "最初に銀行口座を登録すると、次にカードや固定費を紐付けできます。",
                        shouldConfirmReplacement: shouldConfirmSampleDataReplacement,
                        applySampleData: applySampleData
                    )
                } else {
                    List {
                        if !activeBanks.isEmpty {
                            Section {
                                ForEach(activeBanks) { bank in
                                    NavigationLink {
                                        BankDetailView(bank: bank)
                                    } label: {
                                        BankRow(bank: bank)
                                    }
                                    .swipeToDeleteTip(isPresented: bank.id == displayedBanks.first?.id)
                                }
                                .onDelete(perform: deleteActiveBanks)
                                .onMove(perform: moveActiveBanks)
                            } header: {
                                ActiveStatusSectionHeader(isActive: true)
                            }
                        }

                        if !inactiveBanks.isEmpty {
                            Section {
                                ForEach(inactiveBanks) { bank in
                                    NavigationLink {
                                        BankDetailView(bank: bank)
                                    } label: {
                                        BankRow(bank: bank)
                                    }
                                    .swipeToDeleteTip(isPresented: bank.id == displayedBanks.first?.id)
                                }
                                .onDelete(perform: deleteInactiveBanks)
                                .onMove(perform: moveInactiveBanks)
                            } header: {
                                ActiveStatusSectionHeader(isActive: false)
                            }
                        }
                    }
                }
            }
            .navigationTitle("銀行口座")
            .task {
                normalizeSortOrdersIfNeeded()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("銀行口座を追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet, onDismiss: handleAddSheetDismiss) {
                BankEditorView(bank: nil, onDelete: nil, onCreate: {
                    hasCreatedItemInPresentedSheet = true
                })
            }
            .onChange(of: banks.count) { oldValue, newValue in
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

    private func deleteActiveBanks(offsets: IndexSet) {
        let remainingBanks = activeBanks.enumerated()
            .filter { !offsets.contains($0.offset) }
            .map(\.element)

        for index in offsets {
            modelContext.delete(activeBanks[index])
        }

        remainingBanks.normalizeSortOrders()
        saveModelContext()
    }

    private func deleteInactiveBanks(offsets: IndexSet) {
        let remainingBanks = inactiveBanks.enumerated()
            .filter { !offsets.contains($0.offset) }
            .map(\.element)

        for index in offsets {
            modelContext.delete(inactiveBanks[index])
        }

        remainingBanks.normalizeSortOrders()
        saveModelContext()
    }

    private func moveActiveBanks(from source: IndexSet, to destination: Int) {
        var reorderedBanks = activeBanks
        reorderedBanks.move(fromOffsets: source, toOffset: destination)
        reorderedBanks.normalizeSortOrders()
        saveModelContext()
    }

    private func moveInactiveBanks(from source: IndexSet, to destination: Int) {
        var reorderedBanks = inactiveBanks
        reorderedBanks.move(fromOffsets: source, toOffset: destination)
        reorderedBanks.normalizeSortOrders()
        saveModelContext()
    }

    private var displayedBanks: [Bank] {
        banks.sortedForDisplay()
    }

    private var activeBanks: [Bank] {
        displayedBanks.filter(\.isActive)
    }

    private var inactiveBanks: [Bank] {
        displayedBanks.filter { !$0.isActive }
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
        let didChange = activeBanks.normalizeSortOrders() || inactiveBanks.normalizeSortOrders()

        guard didChange else {
            return
        }

        saveModelContext()
    }

    private func saveModelContext() {
        try? modelContext.save()
    }
}

private struct BankRow: View {
    let bank: Bank

    var body: some View {
        ActiveStatusRow(bank, title: bank.name, showIndicator: false)
    }
}

#Preview {
    BankTabView()
        .modelContainer(PreviewData.makeModelContainer())
}
