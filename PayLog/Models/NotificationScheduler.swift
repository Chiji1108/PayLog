//
//  NotificationScheduler.swift
//  PayLog
//
//  Created by Codex on 2026/03/29.
//

import Foundation
import SwiftData
import UserNotifications

@MainActor
final class NotificationScheduler {
    static let shared = NotificationScheduler()

    private let center = UNUserNotificationCenter.current()
    private let calendar = Calendar.autoupdatingCurrent
    private let maximumPendingNotifications = 64

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

    private func buildRequests(
        cards: [Card],
        cardSettings: CardNotificationSettings
    ) -> [ScheduledNotificationRequest] {
        var requests: [ScheduledNotificationRequest] = []

        if cardSettings.closingReminderEnabled {
            requests.append(
                contentsOf: cards.compactMap { card in
                    requestForCardClosing(card, settings: cardSettings)
                }
            )
        }

        if cardSettings.withdrawalReminderEnabled {
            requests.append(
                contentsOf: cards.compactMap { card in
                    requestForCardWithdrawal(card, settings: cardSettings)
                }
            )
        }

        return requests
    }

    private func requestForCardClosing(
        _ card: Card,
        settings: CardNotificationSettings
    ) -> ScheduledNotificationRequest? {
        guard card.isActive else {
            return nil
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
    ) -> ScheduledNotificationRequest? {
        guard card.isActive else {
            return nil
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
    ) -> ScheduledNotificationRequest? {
        guard let eventDay else {
            return nil
        }

        if let repeatingRequest = repeatingMonthlyRequest(
            identifier: identifier,
            content: content,
            eventDay: eventDay,
            daysBefore: daysBefore,
            time: time
        ) {
            return repeatingRequest
        }

        guard let triggerDate = nextNotificationDate(
            using: statusProvider,
            daysBefore: daysBefore,
            time: time
        ) else {
            return nil
        }

        return ScheduledNotificationRequest(
            identifier: identifier,
            triggerDate: triggerDate,
            content: content
        )
    }

    private func repeatingMonthlyRequest(
        identifier: String,
        content: UNNotificationContent,
        eventDay: Int,
        daysBefore: Int,
        time: NotificationTime
    ) -> ScheduledNotificationRequest? {
        guard (1...28).contains(eventDay),
              daysBefore >= 0,
              eventDay - daysBefore >= 1 else {
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

    private func nextNotificationDate(
        using statusProvider: (Date) -> BillingScheduleStatus?,
        daysBefore: Int,
        time: NotificationTime
    ) -> Date? {
        let now = Date.now

        guard let firstStatus = statusProvider(now),
              let firstDate = notificationDate(for: firstStatus.nextDate, daysBefore: daysBefore, time: time) else {
            return nil
        }

        if firstDate > now {
            return firstDate
        }

        guard let nextReferenceDate = calendar.date(byAdding: .day, value: 1, to: firstStatus.nextDate),
              let nextStatus = statusProvider(nextReferenceDate) else {
            return nil
        }

        return notificationDate(for: nextStatus.nextDate, daysBefore: daysBefore, time: time)
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
