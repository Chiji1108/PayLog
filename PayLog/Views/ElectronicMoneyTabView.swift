//
//  ElectronicMoneyTabView.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI
import SwiftData

struct ElectronicMoneyTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var electronicMoneys: [ElectronicMoney]
    @State private var showingAddSheet = false

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
                                }
                                .onDelete(perform: deleteActiveElectronicMoneys)
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
                                }
                                .onDelete(perform: deleteInactiveElectronicMoneys)
                            } header: {
                                ActiveStatusSectionHeader(isActive: false)
                            }
                        }
                    }
                }
            }
            .navigationTitle("電子マネー")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("電子マネーを追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                ElectronicMoneyEditorView()
            }
        }
    }

    private func deleteActiveElectronicMoneys(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(activeElectronicMoneys[index])
        }
    }

    private func deleteInactiveElectronicMoneys(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(inactiveElectronicMoneys[index])
        }
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
