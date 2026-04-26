//
//  ElectronicMoneyEditorView.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI
import SwiftData

struct ElectronicMoneyEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Card.name) private var cards: [Card]

    private let electronicMoney: ElectronicMoney?
    private let onDelete: (() -> Void)?
    @State private var name = ""
    @State private var notes = ""
    @State private var isActive = true
    @State private var selectedCardID: PersistentIdentifier?
    @State private var showingDeleteConfirmation = false

    init(electronicMoney: ElectronicMoney? = nil, onDelete: (() -> Void)? = nil) {
        self.electronicMoney = electronicMoney
        self.onDelete = onDelete
        _name = State(initialValue: electronicMoney?.name ?? "")
        _notes = State(initialValue: electronicMoney?.notes ?? "")
        _isActive = State(initialValue: electronicMoney?.isActive ?? true)
        _selectedCardID = State(initialValue: electronicMoney?.card?.persistentModelID)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("状態") {
                    Toggle("利用中", isOn: $isActive)
                }

                Section("基本情報") {
                    TextField("電子マネー名", text: $name)
                }

                Section("チャージ元カード") {
                    Picker("カード", selection: $selectedCardID) {
                        Text("未設定").tag(Optional<PersistentIdentifier>.none)

                        ForEach(cards) { card in
                            Text(card.name).tag(Optional(card.persistentModelID))
                        }
                    }
                }

                Section("メモ") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                }

                if electronicMoney != nil {
                    Section("削除") {
                        Button("電子マネーを削除", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                    }
                }
            }
            .navigationTitle(electronicMoney == nil ? "電子マネーを追加" : "電子マネーを編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if let electronicMoney {
                            electronicMoney.name = trimmedName
                            electronicMoney.notes = trimmedNotes
                            electronicMoney.card = selectedCard
                            electronicMoney.isActive = isActive
                        } else {
                            let electronicMoney = ElectronicMoney(
                                name: trimmedName,
                                notes: trimmedNotes,
                                card: selectedCard,
                                isActive: isActive
                            )
                            modelContext.insert(electronicMoney)
                        }
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
            .confirmationDialog(
                "この電子マネーを削除しますか？",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    guard let electronicMoney else {
                        return
                    }

                    modelContext.delete(electronicMoney)
                    onDelete?()
                    dismiss()
                }

                Button("キャンセル", role: .cancel) {
                }
            } message: {
                Text("この操作は元に戻せません。")
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedNotes: String? {
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedNotes.isEmpty ? nil : trimmedNotes
    }

    private var selectedCard: Card? {
        guard let selectedCardID else {
            return nil
        }

        return cards.first { $0.persistentModelID == selectedCardID }
    }
}

#Preview("Electronic Money Editor", traits: .sampleData) {
    @Previewable @Query(sort: \ElectronicMoney.name) var electronicMoneys: [ElectronicMoney]

    ElectronicMoneyEditorView(electronicMoney: electronicMoneys.first!)
}

#Preview("Electronic Money Add", traits: .sampleData) {
    ElectronicMoneyEditorView()
}
