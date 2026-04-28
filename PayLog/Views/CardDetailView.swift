//
//  CardDetailView.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI
import SwiftData

struct CardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var card: Card
    @State private var showingEditSheet = false
    @State private var selectedCalendarDraft: CalendarEventDraft?

    var body: some View {
        List {
            Section("カード") {
                ActiveStatusLabeledContent(item: card)

                if let lastFourDigits = card.lastFourDigits {
                    LabeledContent("末尾4桁", value: lastFourDigits)
                } else {
                    LabeledContent("末尾4桁") {
                        Text("未設定")
                    }
                }
                BillingScheduleProgressView(
                    scheduleLabel: "締日",
                    countdownLabel: "締日",
                    status: card.nextClosingStatus,
                    isActive: card.isActive
                )

                BillingScheduleProgressView(
                    scheduleLabel: "引き落とし日",
                    countdownLabel: "引き落とし",
                    status: card.nextWithdrawalStatus,
                    isActive: card.isActive
                )

                if let bank = card.bank {
                    ActiveStatusLabeledNavigationRow(
                        "引き落とし口座",
                        item: bank,
                        title: bank.name
                    ) {
                        BankDetailView(bank: bank)
                    }
                } else {
                    LabeledContent("引き落とし口座") {
                        Text("未設定")
                    }
                }

                if let annualFeeSubscription = card.annualFeeSubscription {
                    ActiveStatusLabeledNavigationRow(
                        "年会費",
                        item: annualFeeSubscription,
                        title: annualFeeSubscription.name
                    ) {
                        SubscriptionDetailView(subscription: annualFeeSubscription)
                    }
                } else {
                    LabeledContent("年会費") {
                        Text(card.annualFeeSetting.label)
                    }
                }
            }

            Section("メモ") {
                if let notes = card.trimmedNotes {
                    Text(notes)
                } else {
                    Text("未設定")
                        .foregroundStyle(.secondary)
                }
            }

            Section("このカードで支払う固定費") {
                if sortedSubscriptions.isEmpty {
                    Text("まだ固定費はありません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedSubscriptions) { subscription in
                        NavigationLink {
                            SubscriptionDetailView(subscription: subscription)
                        } label: {
                            ActiveStatusRow(
                                subscription,
                                title: subscription.name,
                                trailingText: subscription.amountWithBillingCycleText
                            )
                        }
                    }
                }
            }

            Section("このカードに紐づく電子マネー") {
                if sortedElectronicMoneys.isEmpty {
                    Text("まだ電子マネーはありません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedElectronicMoneys) { electronicMoney in
                        NavigationLink {
                            ElectronicMoneyDetailView(electronicMoney: electronicMoney)
                        } label: {
                            ActiveStatusRow(electronicMoney, title: electronicMoney.name)
                        }
                    }
                }
            }
        }
        .navigationTitle(card.name)
        .toolbar {
            if closingEventDraft != nil || withdrawalEventDraft != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if let closingEventDraft {
                            Button {
                                selectedCalendarDraft = closingEventDraft
                            } label: {
                                Label("締日を追加", systemImage: "calendar.badge.plus")
                            }
                        }

                        if let withdrawalEventDraft {
                            Button {
                                selectedCalendarDraft = withdrawalEventDraft
                            } label: {
                                Label("引き落とし日を追加", systemImage: "calendar.badge.plus")
                            }
                        }
                    } label: {
                        Image(systemName: "calendar.badge.plus")
                    }
                    .accessibilityLabel("カレンダーに追加")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("編集") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            CardEditorView(card: card) {
                dismiss()
            }
        }
        .sheet(item: $selectedCalendarDraft) { draft in
            CalendarEventEditorSheet(draft: draft)
        }
    }

    private var sortedSubscriptions: [SubscriptionItem] {
        (card.subscriptions ?? []).sortedForDisplay()
    }

    private var sortedElectronicMoneys: [ElectronicMoney] {
        (card.electronicMoneys ?? []).sortedForDisplay()
    }

    private var closingEventDraft: CalendarEventDraft? {
        makeEventDraft(
            title: "\(card.name) 締日",
            status: card.nextClosingStatus,
            recurrence: card.normalizedClosingDay.map { .monthly(interval: 1, dayOfMonth: $0) }
        )
    }

    private var withdrawalEventDraft: CalendarEventDraft? {
        makeEventDraft(
            title: "\(card.name) 引き落とし日",
            status: card.nextWithdrawalStatus,
            recurrence: card.normalizedWithdrawalDay.map { .monthly(interval: 1, dayOfMonth: $0) }
        )
    }

    private func makeEventDraft(
        title: String,
        status: BillingScheduleStatus?,
        recurrence: CalendarEventRecurrence?
    ) -> CalendarEventDraft? {
        guard let status else {
            return nil
        }

        let startDate = status.nextDate
        let endDate = Calendar.autoupdatingCurrent.date(byAdding: .day, value: 1, to: startDate) ?? startDate

        return CalendarEventDraft(
            title: title,
            startDate: startDate,
            endDate: endDate,
            isAllDay: true,
            notes: card.trimmedNotes,
            recurrence: recurrence
        )
    }
}

#Preview("Card Detail", traits: .sampleData) {
    @Previewable @Query(sort: \Card.name) var cards: [Card]

    NavigationStack {
        CardDetailView(card: cards.first!)
    }
}
