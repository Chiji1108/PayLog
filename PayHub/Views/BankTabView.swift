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
    @Query(sort: \Bank.name) private var banks: [Bank]
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if banks.isEmpty {
                    SampleDataContentUnavailableView(
                        title: "銀行がまだありません",
                        systemImage: "building.columns",
                        description: "最初に銀行を登録すると、次にカードやサブスクを紐付けできます。",
                        addSampleData: addSampleData
                    )
                } else {
                    List {
                        ForEach(displayedBanks) { bank in
                            NavigationLink {
                                BankDetailView(bank: bank)
                            } label: {
                                ActiveStatusRow(bank, title: bank.name)
                            }
                        }
                        .onDelete(perform: deleteBanks)
                    }
                }
            }
            .navigationTitle("銀行")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("銀行を追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                BankEditorView()
            }
        }
    }

    private func deleteBanks(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(displayedBanks[index])
        }
    }

    private var displayedBanks: [Bank] {
        banks.sortedForDisplay()
    }

    private func addSampleData() {
        SampleDataSeeder.seed(in: modelContext)
    }
}

#Preview {
    BankTabView()
        .modelContainer(PreviewData.makeModelContainer())
}
