//
//  NotificationScheduler.swift
//  PayLog
//
//  Created by Codex on 2026/03/29.
//

import Foundation
import SwiftData
import UserNotifications

struct CardNotificationDeliveryWarning: Identifiable {
    enum Kind: Int, CaseIterable {
        case closing
        case withdrawal

        var label: String {
            switch self {
            case .closing:
                "締日通知"
            case .withdrawal:
                "引き落とし日通知"
            }
        }
    }

    let card: Card
    let kinds: [Kind]

    var id: PersistentIdentifier {
        card.persistentModelID
    }

    var summaryText: String {
        kinds.map(\.label).joined(separator: "・")
    }
}

@MainActor
final class NotificationScheduler {
    static let shared = NotificationScheduler()

    private let center = UNUserNotificationCenter.current()
    private let calendar = Calendar.autoupdatingCurrent
    private let maximumPendingNotifications = 64
    private let nonRepeatingRequestCount = 3

    private init() {}

    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func rescheduleAll(using context: ModelContext) async {
        let status = await authorizationStatus()

        guard [.authorized, .provisional, .ephemeral].contains(status) else {
            center.removeAllPendingNotificationRequests()
            return
        }

        center.removeAllPendingNotificationRequests()

        let cardSettings = NotificationSettingsStore.loadCardSettings()
        let cards = (try? context.fetch(FetchDescriptor<Card>())) ?? []

        let requests = buildRequests(cards: cards, cardSettings: cardSettings)
            .sorted { lhs, rhs in
                switch (lhs.triggerDate, rhs.triggerDate) {
                case let (.some(leftDate), .some(rightDate)):
                    leftDate < rightDate
                case (.some, .none):
                    true
                case (.none, .some):
                    false
                case (.none, .none):
                    lhs.notificationRequest.identifier < rhs.notificationRequest.identifier
                }
            }
            .prefix(maximumPendingNotifications)

        for request in requests {
            try? await center.add(request.notificationRequest)
        }
    }

    func deliveryWarnings(
        for cards: [Card],
        settings: CardNotificationSettings
    ) -> [CardNotificationDeliveryWarning] {
        cards
            .filter(\.isActive)
            .compactMap { card in
                var warningKinds: [CardNotificationDeliveryWarning.Kind] = []

                if settings.closingReminderEnabled,
                   let eventDay = card.normalizedClosingDay,
                   !supportsRepeatingMonthlyNotification(eventDay: eventDay, daysBefore: settings.closingReminderDaysBefore) {
                    warningKinds.append(.closing)
                }

                if settings.withdrawalReminderEnabled,
                   let eventDay = card.normalizedWithdrawalDay,
                   !supportsRepeatingMonthlyNotification(eventDay: eventDay, daysBefore: settings.withdrawalReminderDaysBefore) {
                    warningKinds.append(.withdrawal)
                }

                guard !warningKinds.isEmpty else {
                    return nil
                }

                return CardNotificationDeliveryWarning(card: card, kinds: warningKinds)
            }
            .sorted { lhs, rhs in
                lhs.card.name.localizedStandardCompare(rhs.card.name) == .orderedAscending
            }
    }

    private func buildRequests(
        cards: [Card],
        cardSettings: CardNotificationSettings
    ) -> [ScheduledNotificationRequest] {
        var requests: [ScheduledNotificationRequest] = []

        if cardSettings.closingReminderEnabled {
            requests.append(
                contentsOf: cards.flatMap { card in
                    requestForCardClosing(card, settings: cardSettings)
                }
            )
        }

        if cardSettings.withdrawalReminderEnabled {
            requests.append(
                contentsOf: cards.flatMap { card in
                    requestForCardWithdrawal(card, settings: cardSettings)
                }
            )
        }

        return requests
    }

    private func requestForCardClosing(
        _ card: Card,
        settings: CardNotificationSettings
    ) -> [ScheduledNotificationRequest] {
        guard card.isActive else {
            return []
        }

        let content = UNMutableNotificationContent()
        content.title = "\(card.name) の締日"
        content.body = closingReminderBody(daysBefore: settings.closingReminderDaysBefore)
        content.sound = .default

        return requestForCardSchedule(
            identifier: "card.closing.\(card.persistentModelID)",
            content: content,
            eventDay: card.normalizedClosingDay,
            daysBefore: settings.closingReminderDaysBefore,
            time: settings.closingReminderTime,
            statusProvider: { referenceDate in
                card.closingStatus(referenceDate: referenceDate, calendar: calendar)
            }
        )
    }

    private func requestForCardWithdrawal(
        _ card: Card,
        settings: CardNotificationSettings
    ) -> [ScheduledNotificationRequest] {
        guard card.isActive else {
            return []
        }

        let content = UNMutableNotificationContent()
        content.title = "\(card.name) の引き落とし日"
        content.body = withdrawalReminderBody(daysBefore: settings.withdrawalReminderDaysBefore)
        content.sound = .default

        return requestForCardSchedule(
            identifier: "card.withdrawal.\(card.persistentModelID)",
            content: content,
            eventDay: card.normalizedWithdrawalDay,
            daysBefore: settings.withdrawalReminderDaysBefore,
            time: settings.withdrawalReminderTime,
            statusProvider: { referenceDate in
                card.withdrawalStatus(referenceDate: referenceDate, calendar: calendar)
            }
        )
    }

    private func requestForCardSchedule(
        identifier: String,
        content: UNNotificationContent,
        eventDay: Int?,
        daysBefore: Int,
        time: NotificationTime,
        statusProvider: (Date) -> BillingScheduleStatus?
    ) -> [ScheduledNotificationRequest] {
        guard let eventDay else {
            return []
        }

        if let repeatingRequest = repeatingMonthlyRequest(
            identifier: identifier,
            content: content,
            eventDay: eventDay,
            daysBefore: daysBefore,
            time: time
        ) {
            return [repeatingRequest]
        }

        let triggerDates = nextNotificationDates(
            using: statusProvider,
            daysBefore: daysBefore,
            time: time,
            count: nonRepeatingRequestCount
        )

        guard !triggerDates.isEmpty else {
            return []
        }

        return triggerDates.enumerated().map { index, triggerDate in
            ScheduledNotificationRequest(
                identifier: "\(identifier).\(index)",
                triggerDate: triggerDate,
                content: content
            )
        }
    }

    private func repeatingMonthlyRequest(
        identifier: String,
        content: UNNotificationContent,
        eventDay: Int,
        daysBefore: Int,
        time: NotificationTime
    ) -> ScheduledNotificationRequest? {
        guard supportsRepeatingMonthlyNotification(eventDay: eventDay, daysBefore: daysBefore) else {
            return nil
        }

        let reminderDay = eventDay - daysBefore
        var components = DateComponents()
        components.day = reminderDay
        components.hour = time.hour
        components.minute = time.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        return ScheduledNotificationRequest(
            notificationRequest: UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            ),
            triggerDate: trigger.nextTriggerDate()
        )
    }

    private func nextNotificationDates(
        using statusProvider: (Date) -> BillingScheduleStatus?,
        daysBefore: Int,
        time: NotificationTime,
        count: Int
    ) -> [Date] {
        let now = Date.now
        var dates: [Date] = []
        var referenceDate = now

        while dates.count < count {
            guard let status = statusProvider(referenceDate),
                  let triggerDate = notificationDate(for: status.nextDate, daysBefore: daysBefore, time: time) else {
                break
            }

            if triggerDate > now {
                dates.append(triggerDate)
            }

            guard let nextReferenceDate = calendar.date(byAdding: .day, value: 1, to: status.nextDate) else {
                break
            }

            referenceDate = nextReferenceDate
        }

        return dates
    }

    private func notificationDate(for eventDate: Date, daysBefore: Int, time: NotificationTime) -> Date? {
        guard let reminderDate = calendar.date(
            byAdding: .day,
            value: -max(daysBefore, 0),
            to: calendar.startOfDay(for: eventDate)
        ) else {
            return nil
        }

        let components = calendar.dateComponents([.year, .month, .day], from: reminderDate)
        return calendar.date(
            from: DateComponents(
                year: components.year,
                month: components.month,
                day: components.day,
                hour: time.hour,
                minute: time.minute
            )
        )
    }

    private func dayBeforeText(_ value: Int) -> String {
        value == 0 ? "当日" : "\(value)日前"
    }

    private func supportsRepeatingMonthlyNotification(eventDay: Int, daysBefore: Int) -> Bool {
        (1...28).contains(eventDay)
            && daysBefore >= 0
            && eventDay - daysBefore >= 1
    }

    private func closingReminderBody(daysBefore: Int) -> String {
        switch daysBefore {
        case 0:
            return "締日です。"
        case 1:
            return "締日は明日です。"
        default:
            return "締日は\(daysBefore)日後です。"
        }
    }

    private func withdrawalReminderBody(daysBefore: Int) -> String {
        switch daysBefore {
        case 0:
            return "引き落とし日です。"
        case 1:
            return "引き落とし日は明日です。"
        default:
            return "引き落とし日は\(daysBefore)日後です。"
        }
    }
}

private struct ScheduledNotificationRequest {
    let notificationRequest: UNNotificationRequest
    let triggerDate: Date?

    init(identifier: String, triggerDate: Date, content: UNNotificationContent) {
        self.init(
            notificationRequest: UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: UNCalendarNotificationTrigger(
                    dateMatching: Calendar.autoupdatingCurrent.dateComponents(
                        [.year, .month, .day, .hour, .minute],
                        from: triggerDate
                    ),
                    repeats: false
                )
            ),
            triggerDate: triggerDate
        )
    }

    init(notificationRequest: UNNotificationRequest, triggerDate: Date?) {
        self.notificationRequest = notificationRequest
        self.triggerDate = triggerDate
    }
}
