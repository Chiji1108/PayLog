//
//  ElectronicMoneyDetailView.swift
//  PayLog
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
            Section("ウォレット") {
                ActiveStatusLabeledContent(item: electronicMoney)
                LabeledContent("入金方法", value: electronicMoney.fundingSource.label)
                fundingSourceContent
            }

            if let notes = electronicMoney.trimmedNotes {
                Section("メモ") {
                    Text(notes)
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
            ElectronicMoneyEditorView(electronicMoney: electronicMoney, onCreate: {
                dismiss()
            })
        }
    }

    @ViewBuilder
    private var fundingSourceContent: some View {
        switch electronicMoney.fundingSource {
        case .card:
            if let card = electronicMoney.card {
                ActiveStatusLabeledNavigationRow(
                    "入金元",
                    item: card,
                    title: card.name
                ) {
                    CardDetailView(card: card)
                }
            } else {
                LabeledContent("入金元") {
                    Text("未設定")
                }
            }
        case .bankAccount:
            if let bank = electronicMoney.bank {
                ActiveStatusLabeledNavigationRow(
                    "入金元",
                    item: bank,
                    title: bank.name
                ) {
                    BankDetailView(bank: bank)
                }
            } else {
                LabeledContent("入金元") {
                    Text("未設定")
                }
            }
        case .cash, .unspecified:
            EmptyView()
        }
    }
}

#Preview("Electronic Money Detail", traits: .sampleData) {
    @Previewable @Query(sort: \ElectronicMoney.name) var electronicMoneys: [ElectronicMoney]

    NavigationStack {
        ElectronicMoneyDetailView(electronicMoney: electronicMoneys.first!)
    }
}
