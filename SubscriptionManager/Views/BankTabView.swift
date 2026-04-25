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
                    ContentUnavailableView(
                        "銀行がまだありません",
                        systemImage: "building.columns",
                        description: Text("最初に銀行を登録すると、次にカードやサブスクを紐付けできます。")
                    )
                } else {
                    List {
                        ForEach(banks) { bank in
                            NavigationLink {
                                BankDetailView(bank: bank)
                            } label: {
                                BankRow(bank: bank)
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
            modelContext.delete(banks[index])
        }
    }
}

private struct BankRow: View {
    @Bindable var bank: Bank

    var body: some View {
        HStack {
            ActiveStatusIndicator(bank)

            Text(bank.name)
                .font(.headline)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BankTabView()
        .modelContainer(PreviewData.makeModelContainer())
}
