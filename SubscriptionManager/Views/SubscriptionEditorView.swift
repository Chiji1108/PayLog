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

    private let subscription: SubscriptionItem?
    private let onDelete: (() -> Void)?
    @State private var name = ""
    @State private var monthlyAmount = 0
    @State private var isActive = true
    @State private var selectedCard: Card?
    @State private var showingDeleteConfirmation = false

    init(subscription: SubscriptionItem? = nil, onDelete: (() -> Void)? = nil) {
        self.subscription = subscription
        self.onDelete = onDelete
        _name = State(initialValue: subscription?.name ?? "")
        _monthlyAmount = State(initialValue: subscription?.monthlyAmount ?? 0)
        _isActive = State(initialValue: subscription?.isActive ?? true)
        _selectedCard = State(initialValue: subscription?.card)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("サブスク名", text: $name)
                TextField("月額", value: $monthlyAmount, format: .number)
                    .keyboardType(.numberPad)

                Picker("カード", selection: $selectedCard) {
                    ForEach(cards) { card in
                        Text(card.name).tag(card as Card?)
                    }
                }

                Toggle("アクティブ", isOn: $isActive)

                if subscription != nil {
                    Section {
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
                        guard let selectedCard else {
                            return
                        }

                        if let subscription {
                            subscription.name = trimmedName
                            subscription.monthlyAmount = monthlyAmount
                            subscription.card = selectedCard
                            subscription.isActive = isActive
                        } else {
                            let subscription = SubscriptionItem(
                                name: trimmedName,
                                monthlyAmount: monthlyAmount,
                                card: selectedCard,
                                isActive: isActive
                            )
                            modelContext.insert(subscription)
                        }
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty || selectedCard == nil || monthlyAmount <= 0)
                }
            }
            .onAppear {
                selectedCard = selectedCard ?? cards.first
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
}

#Preview("Subscription Editor", traits: .sampleData) {
    @Previewable @Query(sort: \SubscriptionItem.name) var subscriptions: [SubscriptionItem]

    SubscriptionEditorView(subscription: subscriptions.first!)
}

#Preview("Subscription Add", traits: .sampleData) {
    SubscriptionEditorView()
}
