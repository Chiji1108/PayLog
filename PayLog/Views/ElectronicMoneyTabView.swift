//
//  ElectronicMoneyTabView.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI
import SwiftData
import TipKit

struct ElectronicMoneyTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        sort: [
            SortDescriptor(\ElectronicMoney.sortOrder),
            SortDescriptor(\ElectronicMoney.createdAt, order: .reverse),
            SortDescriptor(\ElectronicMoney.name)
        ]
    ) private var electronicMoneys: [ElectronicMoney]
    @State private var showingAddSheet = false
    @State private var hasCreatedItemInPresentedSheet = false
    @State private var reviewRequestTrigger = 0

    init() {}

    var body: some View {
        NavigationStack {
            Group {
                if electronicMoneys.isEmpty {
                    SampleDataContentUnavailableView(
                        title: "電子マネーがまだありません",
                        systemImage: "iphone.gen3",
                        description: "カードを登録しておくと、スムーズに追加できます。",
                        shouldConfirmReplacement: shouldConfirmSampleDataReplacement,
                        applySampleData: applySampleData
                    )
                } else {
                    List {
                        if !activeElectronicMoneys.isEmpty {
                            Section {
                                ForEach(activeElectronicMoneys) { electronicMoney in
                                    NavigationLink {
                                        ElectronicMoneyDetailView(electronicMoney: electronicMoney)
                                    } label: {
                                        ElectronicMoneyRow(electronicMoney: electronicMoney)
                                    }
                                    .swipeToDeleteTip(isPresented: electronicMoney.id == displayedElectronicMoneys.first?.id)
                                }
                                .onDelete(perform: deleteActiveElectronicMoneys)
                                .onMove(perform: moveActiveElectronicMoneys)
                            } header: {
                                ActiveStatusSectionHeader(isActive: true)
                            }
                        }

                        if !inactiveElectronicMoneys.isEmpty {
                            Section {
                                ForEach(inactiveElectronicMoneys) { electronicMoney in
                                    NavigationLink {
                                        ElectronicMoneyDetailView(electronicMoney: electronicMoney)
                                    } label: {
                                        ElectronicMoneyRow(electronicMoney: electronicMoney)
                                    }
                                    .swipeToDeleteTip(isPresented: electronicMoney.id == displayedElectronicMoneys.first?.id)
                                }
                                .onDelete(perform: deleteInactiveElectronicMoneys)
                                .onMove(perform: moveInactiveElectronicMoneys)
                            } header: {
                                ActiveStatusSectionHeader(isActive: false)
                            }
                        }
                    }
                }
            }
            .navigationTitle("電子マネー")
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
                        Label("電子マネーを追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet, onDismiss: handleAddSheetDismiss) {
                ElectronicMoneyEditorView(electronicMoney: nil, onDelete: nil, onCreate: {
                    hasCreatedItemInPresentedSheet = true
                })
            }
            .onChange(of: electronicMoneys.count) { oldValue, newValue in
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

    private func deleteActiveElectronicMoneys(offsets: IndexSet) {
        let remainingElectronicMoneys = activeElectronicMoneys.enumerated()
            .filter { !offsets.contains($0.offset) }
            .map(\.element)

        for index in offsets {
            modelContext.delete(activeElectronicMoneys[index])
        }

        remainingElectronicMoneys.normalizeSortOrders()
        saveModelContext()
    }

    private func deleteInactiveElectronicMoneys(offsets: IndexSet) {
        let remainingElectronicMoneys = inactiveElectronicMoneys.enumerated()
            .filter { !offsets.contains($0.offset) }
            .map(\.element)

        for index in offsets {
            modelContext.delete(inactiveElectronicMoneys[index])
        }

        remainingElectronicMoneys.normalizeSortOrders()
        saveModelContext()
    }

    private func moveActiveElectronicMoneys(from source: IndexSet, to destination: Int) {
        var reorderedElectronicMoneys = activeElectronicMoneys
        reorderedElectronicMoneys.move(fromOffsets: source, toOffset: destination)
        reorderedElectronicMoneys.normalizeSortOrders()
        saveModelContext()
    }

    private func moveInactiveElectronicMoneys(from source: IndexSet, to destination: Int) {
        var reorderedElectronicMoneys = inactiveElectronicMoneys
        reorderedElectronicMoneys.move(fromOffsets: source, toOffset: destination)
        reorderedElectronicMoneys.normalizeSortOrders()
        saveModelContext()
    }

    private var displayedElectronicMoneys: [ElectronicMoney] {
        electronicMoneys.sortedForDisplay()
    }

    private var activeElectronicMoneys: [ElectronicMoney] {
        displayedElectronicMoneys.filter(\.isActive)
    }

    private var inactiveElectronicMoneys: [ElectronicMoney] {
        displayedElectronicMoneys.filter { !$0.isActive }
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
        let didChange = activeElectronicMoneys.normalizeSortOrders()
            || inactiveElectronicMoneys.normalizeSortOrders()

        guard didChange else {
            return
        }

        saveModelContext()
    }

    private func saveModelContext() {
        try? modelContext.save()
    }
}

private struct ElectronicMoneyRow: View {
    let electronicMoney: ElectronicMoney

    var body: some View {
        ActiveStatusRow(electronicMoney, title: electronicMoney.name, showIndicator: false)
    }
}

#Preview {
    ElectronicMoneyTabView()
        .modelContainer(PreviewData.makeModelContainer())
}
