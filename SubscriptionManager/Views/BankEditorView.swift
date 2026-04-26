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
    @State private var branchName = ""
    @State private var accountNumber = ""
    @State private var notes = ""
    @State private var isActive = true
    @State private var showingDeleteConfirmation = false

    init(bank: Bank? = nil, onDelete: (() -> Void)? = nil) {
        self.bank = bank
        self.onDelete = onDelete
        _name = State(initialValue: bank?.name ?? "")
        _branchName = State(initialValue: bank?.branchName ?? "")
        _accountNumber = State(initialValue: bank?.accountNumber ?? "")
        _notes = State(initialValue: bank?.notes ?? "")
        _isActive = State(initialValue: bank?.isActive ?? true)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("状態") {
                    Toggle("利用中", isOn: $isActive)
                }

                Section("基本情報") {
                    TextField("銀行名", text: $name)
                    TextField("支店名", text: $branchName)
                    TextField("口座番号", text: $accountNumber)
                        .keyboardType(.numberPad)
                }

                Section("メモ") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                }

                if bank != nil {
                    Section("削除") {
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
                            bank.branchName = trimmedBranchName
                            bank.accountNumber = trimmedAccountNumber
                            bank.notes = trimmedNotes
                            bank.isActive = isActive
                        } else {
                            let bank = Bank(
                                name: trimmedName,
                                branchName: trimmedBranchName,
                                accountNumber: trimmedAccountNumber,
                                notes: trimmedNotes,
                                isActive: isActive
                            )
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
                Text("紐付いているカードや口座振替の設定は未設定になります。")
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedBranchName: String? {
        normalizedOptionalText(branchName)
    }

    private var trimmedAccountNumber: String? {
        normalizedOptionalText(accountNumber)
    }

    private var trimmedNotes: String? {
        normalizedOptionalText(notes)
    }

    private func normalizedOptionalText(_ text: String) -> String? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText.isEmpty ? nil : trimmedText
    }
}

#Preview("Bank Editor", traits: .sampleData) {
    @Previewable @Query(sort: \Bank.name) var banks: [Bank]

    BankEditorView(bank: banks.first!)
}

#Preview("Bank Add", traits: .sampleData) {
    BankEditorView()
}
