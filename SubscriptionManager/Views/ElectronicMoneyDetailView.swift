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
            DetailStatusSection(electronicMoney)

            if let notes = electronicMoney.trimmedNotes {
                Section("備考") {
                    Text(notes)
                }
            }

            Section("チャージ元カード") {
                NavigationLink {
                    CardDetailView(card: electronicMoney.card)
                } label: {
                    ActiveStatusRow(electronicMoney.card, title: electronicMoney.card.name)
                }
            }
        }
        .navigationTitle(electronicMoney.name)
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
