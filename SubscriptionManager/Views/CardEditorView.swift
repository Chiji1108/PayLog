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
    @State private var lastFourDigits = ""
    @State private var expiryDate = ""
    @State private var notes = ""
    @State private var isActive = true
    @State private var selectedBank: Bank?
    @State private var showingDeleteConfirmation = false

    init(card: Card? = nil, onDelete: (() -> Void)? = nil) {
        self.card = card
        self.onDelete = onDelete
        _name = State(initialValue: card?.name ?? "")
        _lastFourDigits = State(initialValue: card?.lastFourDigits ?? "")
        _expiryDate = State(initialValue: card?.expiryDate ?? "")
        _notes = State(initialValue: card?.notes ?? "")
        _isActive = State(initialValue: card?.isActive ?? true)
        _selectedBank = State(initialValue: card?.bank)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("カード名", text: $name)
                    TextField("末尾4桁", text: $lastFourDigits)
                        .keyboardType(.numberPad)
                    TextField("有効期限", text: $expiryDate)
                        .keyboardType(.numbersAndPunctuation)
                }

                Section("引き落とし口座") {
                    Picker("銀行", selection: $selectedBank) {
                        Text("未設定").tag(nil as Bank?)

                        ForEach(banks) { bank in
                            Text(bank.name).tag(bank as Bank?)
                        }
                    }
                }

                Section("備考") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                }

                Section("状態") {
                    Toggle("利用中", isOn: $isActive)
                }

                if card != nil {
                    Section("削除") {
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
                        if let card {
                            card.name = trimmedName
                            card.lastFourDigits = trimmedLastFourDigits
                            card.expiryDate = trimmedExpiryDate
                            card.notes = trimmedNotes
                            card.bank = selectedBank
                            card.isActive = isActive
                        } else {
                            let card = Card(
                                name: trimmedName,
                                lastFourDigits: trimmedLastFourDigits,
                                expiryDate: trimmedExpiryDate,
                                notes: trimmedNotes,
                                bank: selectedBank,
                                isActive: isActive
                            )
                            modelContext.insert(card)
                        }
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty)
                }
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
                Text("紐付いているサブスクや電子マネーのカード設定は未設定になります。")
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedLastFourDigits: String? {
        normalizedOptionalText(lastFourDigits)
    }

    private var trimmedExpiryDate: String? {
        normalizedOptionalText(expiryDate)
    }

    private var trimmedNotes: String? {
        normalizedOptionalText(notes)
    }

    private func normalizedOptionalText(_ text: String) -> String? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText.isEmpty ? nil : trimmedText
    }
}

#Preview("Card Editor", traits: .sampleData) {
    @Previewable @Query(sort: \Card.name) var cards: [Card]

    CardEditorView(card: cards.first!)
}

#Preview("Card Add", traits: .sampleData) {
    CardEditorView()
}
