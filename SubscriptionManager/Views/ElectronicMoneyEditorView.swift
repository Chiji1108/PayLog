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
    @State private var isActive = true
    @State private var selectedCard: Card?
    @State private var showingDeleteConfirmation = false

    init(electronicMoney: ElectronicMoney? = nil, onDelete: (() -> Void)? = nil) {
        self.electronicMoney = electronicMoney
        self.onDelete = onDelete
        _name = State(initialValue: electronicMoney?.name ?? "")
        _isActive = State(initialValue: electronicMoney?.isActive ?? true)
        _selectedCard = State(initialValue: electronicMoney?.card)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("電子マネー名", text: $name)

                Picker("カード", selection: $selectedCard) {
                    ForEach(cards) { card in
                        Text(card.name).tag(card as Card?)
                    }
                }

                Toggle("アクティブ", isOn: $isActive)

                if electronicMoney != nil {
                    Section {
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
                        guard let selectedCard else {
                            return
                        }

                        if let electronicMoney {
                            electronicMoney.name = trimmedName
                            electronicMoney.card = selectedCard
                            electronicMoney.isActive = isActive
                        } else {
                            let electronicMoney = ElectronicMoney(
                                name: trimmedName,
                                card: selectedCard,
                                isActive: isActive
                            )
                            modelContext.insert(electronicMoney)
                        }
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty || selectedCard == nil)
                }
            }
            .onAppear {
                selectedCard = selectedCard ?? cards.first
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
}

#Preview("Electronic Money Editor", traits: .sampleData) {
    @Previewable @Query(sort: \ElectronicMoney.name) var electronicMoneys: [ElectronicMoney]

    ElectronicMoneyEditorView(electronicMoney: electronicMoneys.first!)
}

#Preview("Electronic Money Add", traits: .sampleData) {
    ElectronicMoneyEditorView()
}
