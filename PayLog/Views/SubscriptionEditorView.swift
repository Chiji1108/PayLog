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
    @State private var billingDay: Int?
    @State private var billingMonth: Int?
    @State private var billingCycle: SubscriptionBillingCycle = .monthly
    @State private var paymentMethod: SubscriptionPaymentMethod = .card
    @State private var notes = ""
    @State private var isActive = true
    @State private var selectedCardID: PersistentIdentifier?
    @State private var selectedBankID: PersistentIdentifier?
    @State private var deleteRequest: DeleteRequest<SubscriptionItem>?

    init(subscription: SubscriptionItem? = nil, onDelete: (() -> Void)? = nil) {
        self.subscription = subscription
        self.onDelete = onDelete
        _name = State(initialValue: subscription?.name ?? "")
        _amount = State(initialValue: subscription?.amount)
        _billingDay = State(initialValue: subscription?.billingDay)
        _billingMonth = State(initialValue: subscription?.billingMonth)
        _billingCycle = State(initialValue: subscription?.billingCycle ?? .monthly)
        _paymentMethod = State(initialValue: subscription?.paymentMethod ?? .card)
        _notes = State(initialValue: subscription?.notes ?? "")
        _isActive = State(initialValue: subscription?.isActive ?? true)
        _selectedCardID = State(initialValue: subscription?.card?.persistentModelID)
        _selectedBankID = State(initialValue: subscription?.bank?.persistentModelID)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("状態") {
                    Toggle("利用中", isOn: $isActive)
                }

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

                if isActive {
                    Section {
                        switch billingCycle {
                        case .monthly:
                            DayOfMonthPicker(title: "請求日", selection: $billingDay)
                        case .yearly:
                            MonthDayPicker(
                                monthTitle: "請求月",
                                dayTitle: "請求日",
                                monthSelection: $billingMonth,
                                daySelection: $billingDay
                            )
                        }
                    } header: {
                        Text("請求スケジュール")
                    } footer: {
                        Text("存在しない日は月末に丸めます。2月29日は平年では2月28日扱いです。")
                    }
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
                            Picker("カード", selection: $selectedCardID) {
                                Text("未設定").tag(Optional<PersistentIdentifier>.none)

                                ForEach(cards) { card in
                                    Text(card.name).tag(Optional(card.persistentModelID))
                                }
                            }
                        }
                    case .bankAccount:
                        if banks.isEmpty {
                            Text("利用可能な銀行口座がありません")
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("銀行口座", selection: $selectedBankID) {
                                Text("未設定").tag(Optional<PersistentIdentifier>.none)

                                ForEach(banks) { bank in
                                    Text(bank.name).tag(Optional(bank.persistentModelID))
                                }
                            }
                        }
                    }
                }

                Section("メモ") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                }

                if subscription != nil {
                    Section("削除") {
                        Button("サブスクを削除", role: .destructive) {
                            guard let subscription else {
                                return
                            }

                            deleteRequest = DeleteRequest(item: subscription)
                        }
                        .deleteConfirmation(request: $deleteRequest, onConfirm: deleteSubscription)
                    }
                }
            }
            .navigationTitle(subscription == nil ? "サブスクを追加" : "サブスクを編集")
            .onChange(of: billingCycle) { _, newValue in
                if newValue == .monthly {
                    billingMonth = nil
                }
            }
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

                        if let subscription {
                            subscription.name = trimmedName
                            subscription.amount = amount
                            subscription.billingDay = billingDay
                            subscription.billingMonth = normalizedBillingMonth
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
                                billingDay: billingDay,
                                billingMonth: normalizedBillingMonth,
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
                    .disabled(trimmedName.isEmpty || !hasValidAmount || !hasValidBillingSchedule)
                }
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

    private var selectedBank: Bank? {
        guard let selectedBankID else {
            return nil
        }

        return banks.first { $0.persistentModelID == selectedBankID }
    }

    private var hasValidAmount: Bool {
        guard let amount else {
            return false
        }

        return amount > 0
    }

    private var normalizedBillingMonth: Int? {
        billingCycle == .yearly ? billingMonth : nil
    }

    private var hasValidBillingSchedule: Bool {
        guard isActive else {
            return true
        }

        switch billingCycle {
        case .monthly:
            return true
        case .yearly:
            return (billingMonth == nil && billingDay == nil) || (billingMonth != nil && billingDay != nil)
        }
    }

    private func deleteSubscription(_ subscription: SubscriptionItem) {
        modelContext.delete(subscription)
        onDelete?()
        dismiss()
    }
}

#Preview("Subscription Editor", traits: .sampleData) {
    @Previewable @Query(sort: \SubscriptionItem.name) var subscriptions: [SubscriptionItem]

    SubscriptionEditorView(subscription: subscriptions.first!)
}

#Preview("Subscription Add", traits: .sampleData) {
    SubscriptionEditorView()
}
