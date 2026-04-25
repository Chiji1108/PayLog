//
//  SubscriptionEditorView.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI
import SwiftData

struct SubscriptionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Card.name) private var cards: [Card]
    @Query(sort: \Bank.name) private var banks: [Bank]

    private let subscription: SubscriptionItem?
    private let onDelete: (() -> Void)?
    @State private var name = ""
    @State private var amount: Int?
    @State private var billingCycle: SubscriptionBillingCycle = .monthly
    @State private var paymentMethod: SubscriptionPaymentMethod = .card
    @State private var notes = ""
    @State private var isActive = true
    @State private var selectedCard: Card?
    @State private var selectedBank: Bank?
    @State private var showingDeleteConfirmation = false

    init(subscription: SubscriptionItem? = nil, onDelete: (() -> Void)? = nil) {
        self.subscription = subscription
        self.onDelete = onDelete
        _name = State(initialValue: subscription?.name ?? "")
        _amount = State(initialValue: subscription?.amount)
        _billingCycle = State(initialValue: subscription?.billingCycle ?? .monthly)
        _paymentMethod = State(initialValue: subscription?.paymentMethod ?? .card)
        _notes = State(initialValue: subscription?.notes ?? "")
        _isActive = State(initialValue: subscription?.isActive ?? true)
        _selectedCard = State(initialValue: subscription?.card)
        _selectedBank = State(initialValue: subscription?.bank)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("サブスク名", text: $name)
                    Picker("請求サイクル", selection: $billingCycle) {
                        ForEach(SubscriptionBillingCycle.allCases) { cycle in
                            Text(cycle.label).tag(cycle)
                        }
                    }
                    TextField("金額", value: $amount, format: .number)
                        .keyboardType(.numberPad)
                }

                Section("支払い方法") {
                    Picker("方法", selection: $paymentMethod) {
                        ForEach(SubscriptionPaymentMethod.allCases) { method in
                            Text(method.label).tag(method)
                        }
                    }

                    switch paymentMethod {
                    case .card:
                        if cards.isEmpty {
                            Text("利用可能なカードがありません")
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("カード", selection: $selectedCard) {
                                ForEach(cards) { card in
                                    Text(card.name).tag(card as Card?)
                                }
                            }
                        }
                    case .bankAccount:
                        if banks.isEmpty {
                            Text("利用可能な銀行口座がありません")
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("銀行口座", selection: $selectedBank) {
                                ForEach(banks) { bank in
                                    Text(bank.name).tag(bank as Bank?)
                                }
                            }
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

                if subscription != nil {
                    Section("削除") {
                        Button("サブスクを削除", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                    }
                }
            }
            .navigationTitle(subscription == nil ? "サブスクを追加" : "サブスクを編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let amount, amount > 0 else {
                            return
                        }

                        let selectedCard = paymentMethod == .card ? selectedCard : nil
                        let selectedBank = paymentMethod == .bankAccount ? selectedBank : nil

                        guard selectedCard != nil || selectedBank != nil else {
                            return
                        }

                        if let subscription {
                            subscription.name = trimmedName
                            subscription.amount = amount
                            subscription.billingCycle = billingCycle
                            subscription.paymentMethod = paymentMethod
                            subscription.notes = trimmedNotes
                            subscription.card = selectedCard
                            subscription.bank = selectedBank
                            subscription.isActive = isActive
                        } else {
                            let subscription = SubscriptionItem(
                                name: trimmedName,
                                amount: amount,
                                billingCycle: billingCycle,
                                paymentMethod: paymentMethod,
                                notes: trimmedNotes,
                                card: selectedCard,
                                bank: selectedBank,
                                isActive: isActive
                            )
                            modelContext.insert(subscription)
                        }
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty || !hasValidAmount || !hasValidPaymentMethod)
                }
            }
            .onAppear {
                applyDefaultPaymentSelection(for: paymentMethod)
            }
            .onChange(of: paymentMethod) { _, newValue in
                applyDefaultPaymentSelection(for: newValue)
            }
            .confirmationDialog(
                "このサブスクを削除しますか？",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    guard let subscription else {
                        return
                    }

                    modelContext.delete(subscription)
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

    private var hasValidAmount: Bool {
        guard let amount else {
            return false
        }

        return amount > 0
    }

    private var hasValidPaymentMethod: Bool {
        switch paymentMethod {
        case .card:
            selectedCard != nil
        case .bankAccount:
            selectedBank != nil
        }
    }

    private func applyDefaultPaymentSelection(for paymentMethod: SubscriptionPaymentMethod) {
        switch paymentMethod {
        case .card:
            selectedCard = selectedCard ?? cards.first
        case .bankAccount:
            selectedBank = selectedBank ?? banks.first
        }
    }
}

#Preview("Subscription Editor", traits: .sampleData) {
    @Previewable @Query(sort: \SubscriptionItem.name) var subscriptions: [SubscriptionItem]

    SubscriptionEditorView(subscription: subscriptions.first!)
}

#Preview("Subscription Add", traits: .sampleData) {
    SubscriptionEditorView()
}
