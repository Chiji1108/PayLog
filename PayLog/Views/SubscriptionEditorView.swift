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
    @State private var billingInterval = 1
    @State private var billingUnit: SubscriptionBillingUnit = .month
    @State private var billingAnchorDate = Calendar.autoupdatingCurrent.startOfDay(for: Date.now)
    @State private var paymentMethod: SubscriptionPaymentMethod = .unspecified
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
        _billingInterval = State(initialValue: max(subscription?.billingInterval ?? 1, 1))
        _billingUnit = State(initialValue: subscription?.billingUnit ?? .month)
        _billingAnchorDate = State(
            initialValue: Calendar.autoupdatingCurrent.startOfDay(for: subscription?.billingAnchorDate ?? .now)
        )
        _paymentMethod = State(initialValue: subscription?.paymentMethod ?? .unspecified)
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
                    TextField("固定費名", text: $name)
                }

                Section {
                    TextField("金額", value: $amount, format: .number)
                        .keyboardType(.numberPad)

                    Stepper(value: $billingInterval, in: 1...24) {
                        LabeledContent("間隔", value: billingFrequency.intervalDescription)
                    }

                    Picker("単位", selection: $billingUnit) {
                        ForEach(SubscriptionBillingUnit.allCases) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }

                    DatePicker("基準日", selection: $billingAnchorDate, displayedComponents: .date)
                } header: {
                    Text("請求情報")
                } footer: {
                    Text(billingScheduleFooter)
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
                    case .invoice, .onSite, .unspecified:
                        EmptyView()
                    }
                }

                Section("メモ") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                }

                if subscription != nil {
                    Section("削除") {
                        Button("固定費を削除", role: .destructive) {
                            guard let subscription else {
                                return
                            }

                            deleteRequest = DeleteRequest(item: subscription)
                        }
                        .deleteConfirmation(request: $deleteRequest, onConfirm: deleteSubscription)
                    }
                }
            }
            .navigationTitle(subscription == nil ? "固定費を追加" : "固定費を編集")
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
                            subscription.billingInterval = billingInterval
                            subscription.billingUnit = billingUnit
                            subscription.billingAnchorDate = normalizedAnchorDate
                            subscription.paymentMethod = paymentMethod
                            subscription.notes = trimmedNotes
                            subscription.card = selectedCard
                            subscription.bank = selectedBank
                            subscription.isActive = isActive
                        } else {
                            let subscription = SubscriptionItem(
                                name: trimmedName,
                                amount: amount,
                                billingInterval: billingInterval,
                                billingUnit: billingUnit,
                                billingAnchorDate: normalizedAnchorDate,
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
                    .disabled(trimmedName.isEmpty || !hasValidAmount)
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

    private var billingFrequency: SubscriptionBillingFrequency {
        SubscriptionBillingFrequency(interval: billingInterval, unit: billingUnit)
    }

    private var normalizedAnchorDate: Date {
        Calendar.autoupdatingCurrent.startOfDay(for: billingAnchorDate)
    }

    private var hasValidAmount: Bool {
        guard let amount else {
            return false
        }

        return amount > 0
    }

    private var billingScheduleFooter: String {
        switch billingUnit {
        case .week:
            "選んだ基準日を起点に、同じ曜日で繰り返します。2週間以上では基準日も周期の判定に使います。"
        case .month:
            "選んだ基準日を起点に、同じ日付で繰り返します。存在しない日は月末に丸めます。"
        case .year:
            "選んだ基準日を起点に、同じ月日で繰り返します。2月29日は平年では2月28日扱いです。"
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
