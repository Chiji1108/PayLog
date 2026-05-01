//
//  BankTabView.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI
import SwiftData

struct BankTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var banks: [Bank]
    @State private var showingAddSheet = false
    @State private var hasCreatedItemInPresentedSheet = false
    @State private var reviewRequestTrigger = 0

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
                                }
                                .onDelete(perform: deleteActiveBanks)
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
                                }
                                .onDelete(perform: deleteInactiveBanks)
                            } header: {
                                ActiveStatusSectionHeader(isActive: false)
                            }
                        }
                    }
                }
            }
            .navigationTitle("銀行口座")
            .toolbar {
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
        }
        .reviewRequestAfterCreation(trigger: reviewRequestTrigger)
    }

    private func deleteActiveBanks(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(activeBanks[index])
        }
    }

    private func deleteInactiveBanks(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(inactiveBanks[index])
        }
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
