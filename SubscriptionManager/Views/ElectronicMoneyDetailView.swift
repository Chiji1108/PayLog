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
            Section("基本情報") {
                LabeledContent("状態", value: electronicMoney.statusText)
            }

            Section("関連") {
                NavigationLink {
                    CardDetailView(card: electronicMoney.card)
                } label: {
                    LabeledContent("カード", value: electronicMoney.card.name)
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
