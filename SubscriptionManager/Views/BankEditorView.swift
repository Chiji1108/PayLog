//
//  BankEditorView.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI
import SwiftData

struct BankEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let bank: Bank?
    private let onDelete: (() -> Void)?
    @State private var name = ""
    @State private var isActive = true
    @State private var showingDeleteConfirmation = false

    init(bank: Bank? = nil, onDelete: (() -> Void)? = nil) {
        self.bank = bank
        self.onDelete = onDelete
        _name = State(initialValue: bank?.name ?? "")
        _isActive = State(initialValue: bank?.isActive ?? true)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("銀行名", text: $name)
                Toggle("アクティブ", isOn: $isActive)

                if bank != nil {
                    Section {
                        Button("銀行を削除", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                    }
                }
            }
            .navigationTitle(bank == nil ? "銀行を追加" : "銀行を編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if let bank {
                            bank.name = trimmedName
                            bank.isActive = isActive
                        } else {
                            let bank = Bank(name: trimmedName, isActive: isActive)
                            modelContext.insert(bank)
                        }
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
            .confirmationDialog(
                "この銀行を削除しますか？",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    guard let bank else {
                        return
                    }

                    modelContext.delete(bank)
                    onDelete?()
                    dismiss()
                }

                Button("キャンセル", role: .cancel) {
                }
            } message: {
                Text("紐付いているカードや関連データも削除されます。")
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview("Bank Editor", traits: .sampleData) {
    @Previewable @Query(sort: \Bank.name) var banks: [Bank]

    BankEditorView(bank: banks.first!)
}

#Preview("Bank Add", traits: .sampleData) {
    BankEditorView()
}
