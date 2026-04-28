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
    @Query(sort: \SubscriptionItem.name) private var subscriptions: [SubscriptionItem]

    private let card: Card?
    private let onDelete: (() -> Void)?
    @State private var name = ""
    @State private var lastFourDigits = ""
    @State private var closingDay: Int?
    @State private var withdrawalDay: Int?
    @State private var notes = ""
    @State private var isActive = true
    @State private var selectedBankID: PersistentIdentifier?
    @State private var annualFeeSetting: CardAnnualFeeSetting
    @State private var selectedAnnualFeeSubscriptionID: PersistentIdentifier?
    @State private var deleteRequest: DeleteRequest<Card>?

    init(card: Card? = nil, onDelete: (() -> Void)? = nil) {
        self.card = card
        self.onDelete = onDelete
        _name = State(initialValue: card?.name ?? "")
        _lastFourDigits = State(initialValue: card?.lastFourDigits ?? "")
        _closingDay = State(initialValue: card?.closingDay)
        _withdrawalDay = State(initialValue: card?.withdrawalDay)
        _notes = State(initialValue: card?.notes ?? "")
        _isActive = State(initialValue: card?.isActive ?? true)
        _selectedBankID = State(initialValue: card?.bank?.persistentModelID)
        _annualFeeSetting = State(initialValue: card?.annualFeeSetting ?? .unspecified)
        _selectedAnnualFeeSubscriptionID = State(initialValue: card?.annualFeeSubscription?.persistentModelID)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("カード名", text: $name)
                    Toggle("利用中", isOn: $isActive)
                    TextField("末尾4桁", text: $lastFourDigits)
                        .keyboardType(.numberPad)
                }

                Section("引き落とし口座") {
                    Picker("銀行口座", selection: $selectedBankID) {
                        Text("未設定").tag(Optional<PersistentIdentifier>.none)

                        ForEach(banks) { bank in
                            Text(bank.name).tag(Optional(bank.persistentModelID))
                        }
                    }
                }

                Section {
                    Picker("料金", selection: $annualFeeSetting) {
                        ForEach(CardAnnualFeeSetting.allCases) { setting in
                            Text(setting.label).tag(setting)
                        }
                    }

                    if annualFeeSetting == .paid {
                        Picker("固定費", selection: $selectedAnnualFeeSubscriptionID) {
                            Text("未設定").tag(Optional<PersistentIdentifier>.none)

                            ForEach(availableAnnualFeeSubscriptions) { subscription in
                                Text(subscription.name).tag(Optional(subscription.persistentModelID))
                            }
                        }
                    }
                } header: {
                    Text("年会費")
                } footer: {
                    Text(annualFeeFooterText)
                }

                if isActive {
                    Section {
                        DayOfMonthPicker(title: "締日", selection: $closingDay)
                        DayOfMonthPicker(title: "引き落とし日", selection: $withdrawalDay)
                    } footer: {
                        Text("31日を指定した場合、30日までの月は月末扱いになります。")
                    }
                }

                Section("メモ") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                }

                if card != nil {
                    Section("削除") {
                        Button("カードを削除", role: .destructive) {
                            guard let card else {
                                return
                            }

                            deleteRequest = DeleteRequest(item: card)
                        }
                        .deleteConfirmation(request: $deleteRequest, onConfirm: deleteCard)
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
                            card.closingDay = closingDay
                            card.withdrawalDay = withdrawalDay
                            card.notes = trimmedNotes
                            card.bank = selectedBank
                            card.annualFeeSetting = annualFeeSetting
                            card.annualFeeSubscription = annualFeeSetting == .paid
                                ? selectedAnnualFeeSubscription
                                : nil
                            card.isActive = isActive
                        } else {
                            let card = Card(
                                name: trimmedName,
                                lastFourDigits: trimmedLastFourDigits,
                                closingDay: closingDay,
                                withdrawalDay: withdrawalDay,
                                notes: trimmedNotes,
                                bank: selectedBank,
                                annualFeeSetting: annualFeeSetting,
                                annualFeeSubscription: annualFeeSetting == .paid
                                    ? selectedAnnualFeeSubscription
                                    : nil,
                                isActive: isActive
                            )
                            modelContext.insert(card)
                        }
                        try? modelContext.save()
                        Task {
                            await NotificationScheduler.shared.rescheduleAll(using: modelContext)
                        }
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedLastFourDigits: String? {
        normalizedOptionalText(lastFourDigits)
    }

    private var trimmedNotes: String? {
        normalizedOptionalText(notes)
    }

    private var selectedBank: Bank? {
        guard let selectedBankID else {
            return nil
        }

        return banks.first { $0.persistentModelID == selectedBankID }
    }

    private var selectedAnnualFeeSubscription: SubscriptionItem? {
        guard let selectedAnnualFeeSubscriptionID else {
            return nil
        }

        return subscriptions.first { $0.persistentModelID == selectedAnnualFeeSubscriptionID }
    }

    private var availableAnnualFeeSubscriptions: [SubscriptionItem] {
        subscriptions
            .filter { subscription in
                if subscription.persistentModelID == selectedAnnualFeeSubscriptionID {
                    return true
                }

                guard subscription.billingUnit == .year else {
                    return false
                }

                guard let annualFeeCard = subscription.annualFeeCard else {
                    return true
                }

                return annualFeeCard.persistentModelID == card?.persistentModelID
            }
            .sortedForDisplay()
    }

    private var annualFeeFooterText: String {
        if annualFeeSetting == .paid, availableAnnualFeeSubscriptions.isEmpty {
            return "有料を選んだ場合は固定費も紐づけられます。まだ候補の年単位固定費がありません。"
        }

        return "有料を選んだ場合は固定費も紐づけられます。候補には年単位の固定費だけ表示し、別カードの年会費に使っている固定費は除外します。"
    }

    private func normalizedOptionalText(_ text: String) -> String? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText.isEmpty ? nil : trimmedText
    }

    private func deleteCard(_ card: Card) {
        modelContext.delete(card)
        try? modelContext.save()
        Task {
            await NotificationScheduler.shared.rescheduleAll(using: modelContext)
        }
        onDelete?()
        dismiss()
    }
}

#Preview("Card Editor", traits: .sampleData) {
    @Previewable @Query(sort: \Card.name) var cards: [Card]

    CardEditorView(card: cards.first!)
}

#Preview("Card Add", traits: .sampleData) {
    CardEditorView()
}
