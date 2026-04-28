//
//  AppNotificationSettings.swift
//  PayLog
//
//  Created by Codex on 2026/03/29.
//

import Foundation

struct NotificationTime: Codable, Hashable {
    var hour: Int
    var minute: Int

    static let defaultMorning = NotificationTime(hour: 9, minute: 0)

    var date: Date {
        let calendar = Calendar.autoupdatingCurrent
        return calendar.date(from: DateComponents(hour: hour, minute: minute)) ?? .now
    }

    init(hour: Int, minute: Int) {
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
    }

    init(date: Date, calendar: Calendar = .autoupdatingCurrent) {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        self.init(hour: components.hour ?? 9, minute: components.minute ?? 0)
    }
}

struct CardNotificationSettings: Codable, Hashable {
    var closingReminderEnabled: Bool = false
    var closingReminderDaysBefore: Int = 1
    var closingReminderTime: NotificationTime = .defaultMorning
    var withdrawalReminderEnabled: Bool = false
    var withdrawalReminderDaysBefore: Int = 1
    var withdrawalReminderTime: NotificationTime = .defaultMorning
}

enum NotificationSettingsStore {
    private static let cardKey = "notification_settings.card"

    static func loadCardSettings(defaults: UserDefaults = .standard) -> CardNotificationSettings {
        loadValue(forKey: cardKey, defaults: defaults) ?? CardNotificationSettings()
    }

    static func saveCardSettings(_ settings: CardNotificationSettings, defaults: UserDefaults = .standard) {
        saveValue(settings, forKey: cardKey, defaults: defaults)
    }

    private static func loadValue<T: Decodable>(forKey key: String, defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }

        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func saveValue<T: Encodable>(_ value: T, forKey key: String, defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(value) else {
            return
        }

        defaults.set(data, forKey: key)
    }
}
