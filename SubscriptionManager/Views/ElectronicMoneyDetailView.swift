//
//  ElectronicMoneyDetailView.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI
import SwiftData

struct ElectronicMoneyDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var electronicMoney: ElectronicMoney
    @State private var showingEditSheet = false

    var body: some View {
        List {
            Section("電子マネー") {
                if let card = electronicMoney.card {
                    ActiveStatusLabeledNavigationRow(
                        "チャージ元カード",
                        item: card,
                        title: card.name
                    ) {
                        CardDetailView(card: card)
                    }
                } else {
                    LabeledContent("チャージ元カード", value: "未設定")
                        .foregroundStyle(.secondary)
                }
            }

            if let notes = electronicMoney.trimmedNotes {
                Section("メモ") {
                    Text(notes)
                }
            }
        }
        .navigationTitle(electronicMoney.name)
        .activeStatusBadge(electronicMoney)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("編集") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            ElectronicMoneyEditorView(electronicMoney: electronicMoney) {
                dismiss()
            }
        }
    }
}

#Preview("Electronic Money Detail", traits: .sampleData) {
    @Previewable @Query(sort: \ElectronicMoney.name) var electronicMoneys: [ElectronicMoney]

    NavigationStack {
        ElectronicMoneyDetailView(electronicMoney: electronicMoneys.first!)
    }
}
