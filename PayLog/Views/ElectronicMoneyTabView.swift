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
    @Query(sort: \ElectronicMoney.name) private var electronicMoneys: [ElectronicMoney]
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if electronicMoneys.isEmpty {
                    SampleDataContentUnavailableView(
                        title: "電子マネーがまだありません",
                        systemImage: "iphone.gen3",
                        description: "カードを登録しておくと、スムーズに追加できます。",
                        addSampleData: addSampleData
                    )
                } else {
                    List {
                        ForEach(displayedElectronicMoneys) { electronicMoney in
                            NavigationLink {
                                ElectronicMoneyDetailView(electronicMoney: electronicMoney)
                            } label: {
                                ActiveStatusRow(electronicMoney, title: electronicMoney.name)
                            }
                        }
                        .onDelete(perform: deleteElectronicMoneys)
                    }
                }
            }
            .navigationTitle("電子マネー")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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

    private func deleteElectronicMoneys(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(displayedElectronicMoneys[index])
        }
    }

    private func deleteElectronicMoney(_ electronicMoney: ElectronicMoney) {
        modelContext.delete(electronicMoney)
    }

    private var displayedElectronicMoneys: [ElectronicMoney] {
        electronicMoneys.sortedForDisplay()
    }

    private func addSampleData() {
        SampleDataSeeder.seed(in: modelContext)
    }
}

#Preview {
    ElectronicMoneyTabView()
        .modelContainer(PreviewData.makeModelContainer())
}
