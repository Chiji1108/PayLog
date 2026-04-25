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
    @Query(sort: \Card.name) private var cards: [Card]
    @Query(sort: \ElectronicMoney.name) private var electronicMoneys: [ElectronicMoney]
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if cards.isEmpty {
                    ContentUnavailableView(
                        "先にカードを登録してください",
                        systemImage: "creditcard",
                        description: Text("電子マネーはカードに紐付きます。銀行、カードの順で登録してください。")
                    )
                } else if electronicMoneys.isEmpty {
                    ContentUnavailableView(
                        "電子マネーがまだありません",
                        systemImage: "iphone.gen3",
                        description: Text("右上の追加ボタンから登録できます。")
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
                    .disabled(cards.isEmpty)
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

    private var displayedElectronicMoneys: [ElectronicMoney] {
        electronicMoneys.sortedForDisplay()
    }
}

#Preview {
    ElectronicMoneyTabView()
        .modelContainer(PreviewData.makeModelContainer())
}
