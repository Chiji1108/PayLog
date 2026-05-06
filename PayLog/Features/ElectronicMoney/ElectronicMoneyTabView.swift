//
//  ElectronicMoneyTabView.swift
//  PayLog
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
                        title: "ウォレットがまだありません",
                        systemImage: "iphone.gen3",
                        description: "カードや銀行口座を登録しておくと、スムーズに追加できます。",
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
            .navigationTitle("ウォレット")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    EditModeDisabledToolbarContent {
                        Button {
                            showingAddSheet = true
                        } label: {
                            Label("ウォレットを追加", systemImage: "plus")
                        }
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
        deleteElectronicMoneys(offsets: offsets, from: activeElectronicMoneys)
    }

    private func deleteInactiveElectronicMoneys(offsets: IndexSet) {
        deleteElectronicMoneys(offsets: offsets, from: inactiveElectronicMoneys)
    }

    private func moveActiveElectronicMoneys(from source: IndexSet, to destination: Int) {
        moveElectronicMoneys(from: source, to: destination, in: activeElectronicMoneys)
    }

    private func moveInactiveElectronicMoneys(from source: IndexSet, to destination: Int) {
        moveElectronicMoneys(from: source, to: destination, in: inactiveElectronicMoneys)
    }

    private func deleteElectronicMoneys(offsets: IndexSet, from electronicMoneys: [ElectronicMoney]) {
        let remainingElectronicMoneys = electronicMoneys.enumerated()
            .filter { !offsets.contains($0.offset) }
            .map(\.element)

        for index in offsets {
            modelContext.delete(electronicMoneys[index])
        }

        remainingElectronicMoneys.normalizeSortOrders()
        saveModelContext()
    }

    private func moveElectronicMoneys(from source: IndexSet, to destination: Int, in electronicMoneys: [ElectronicMoney]) {
        var reorderedElectronicMoneys = electronicMoneys
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
