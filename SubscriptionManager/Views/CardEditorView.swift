//
//  CardEditorView.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI
import SwiftData

struct CardEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Bank.name) private var banks: [Bank]

    private let card: Card?
    private let onDelete: (() -> Void)?
    @State private var name = ""
    @State private var isActive = true
    @State private var selectedBank: Bank?
    @State private var showingDeleteConfirmation = false

    init(card: Card? = nil, onDelete: (() -> Void)? = nil) {
        self.card = card
        self.onDelete = onDelete
        _name = State(initialValue: card?.name ?? "")
        _isActive = State(initialValue: card?.isActive ?? true)
        _selectedBank = State(initialValue: card?.bank)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("カード名", text: $name)

                Picker("銀行", selection: $selectedBank) {
                    ForEach(banks) { bank in
                        Text(bank.name).tag(bank as Bank?)
                    }
                }

                Toggle("アクティブ", isOn: $isActive)

                if card != nil {
                    Section {
                        Button("カードを削除", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                    }
                }
            }
            .navigationTitle(card == nil ? "カードを追加" : "カードを編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let selectedBank else {
                            return
                        }

                        if let card {
                            card.name = trimmedName
                            card.bank = selectedBank
                            card.isActive = isActive
                        } else {
                            let card = Card(name: trimmedName, bank: selectedBank, isActive: isActive)
                            modelContext.insert(card)
                        }
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty || selectedBank == nil)
                }
            }
            .onAppear {
                selectedBank = selectedBank ?? banks.first
            }
            .confirmationDialog(
                "このカードを削除しますか？",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    guard let card else {
                        return
                    }

                    modelContext.delete(card)
                    onDelete?()
                    dismiss()
                }

                Button("キャンセル", role: .cancel) {
                }
            } message: {
                Text("紐付いているサブスクや電子マネーも削除されます。")
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview("Card Editor", traits: .sampleData) {
    @Previewable @Query(sort: \Card.name) var cards: [Card]

    CardEditorView(card: cards.first!)
}

#Preview("Card Add", traits: .sampleData) {
    CardEditorView()
}
