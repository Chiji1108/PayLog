//
//  BillingSchedule.swift
//  SubscriptionManager
//
//  Created by Codex on 2026/03/28.
//

import Foundation

struct BillingScheduleStatus {
    let previousDate: Date
    let nextDate: Date
    let referenceDate: Date
    private let calendar: Calendar

    init(
        previousDate: Date,
        nextDate: Date,
        referenceDate: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.previousDate = previousDate
        self.nextDate = nextDate
        self.referenceDate = referenceDate
        self.calendar = calendar
    }

    var progress: Double {
        let totalInterval = nextDate.timeIntervalSince(previousDate)
        guard totalInterval > 0 else {
            return 0
        }

        let elapsedInterval = min(max(referenceDate.timeIntervalSince(previousDate), 0), totalInterval)
        return elapsedInterval / totalInterval
    }

    var daysUntilNext: Int {
        let startOfReferenceDate = calendar.startOfDay(for: referenceDate)
        let startOfNextDate = calendar.startOfDay(for: nextDate)
        return max(calendar.dateComponents([.day], from: startOfReferenceDate, to: startOfNextDate).day ?? 0, 0)
    }
}

enum BillingScheduleCalculator {
    static func normalizedDay(_ day: Int?) -> Int? {
        guard let day, (1...31).contains(day) else {
            return nil
        }

        return day
    }

    static func normalizedMonth(_ month: Int?) -> Int? {
        guard let month, (1...12).contains(month) else {
            return nil
        }

        return month
    }

    static func maximumDay(in month: Int?) -> Int {
        switch month {
        case 2:
            29
        case 4, 6, 9, 11:
            30
        default:
            31
        }
    }

    static func monthlyStatus(
        day: Int,
        referenceDate: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> BillingScheduleStatus? {
        guard let normalizedDay = normalizedDay(day) else {
            return nil
        }

        let startOfReferenceDate = calendar.startOfDay(for: referenceDate)
        let referenceComponents = calendar.dateComponents([.year, .month], from: startOfReferenceDate)

        guard let year = referenceComponents.year,
              let month = referenceComponents.month,
              let currentOccurrence = occurrence(day: normalizedDay, year: year, month: month, calendar: calendar) else {
            return nil
        }

        if currentOccurrence <= startOfReferenceDate {
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentOccurrence) else {
                return nil
            }

            let nextComponents = calendar.dateComponents([.year, .month], from: nextMonth)

            guard let nextYear = nextComponents.year,
                  let nextMonthValue = nextComponents.month,
                  let nextOccurrence = occurrence(
                    day: normalizedDay,
                    year: nextYear,
                    month: nextMonthValue,
                    calendar: calendar
                  ) else {
                return nil
            }

            return BillingScheduleStatus(
                previousDate: currentOccurrence,
                nextDate: nextOccurrence,
                referenceDate: startOfReferenceDate,
                calendar: calendar
            )
        }

        guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentOccurrence) else {
            return nil
        }

        let previousComponents = calendar.dateComponents([.year, .month], from: previousMonth)

        guard let previousYear = previousComponents.year,
              let previousMonthValue = previousComponents.month,
              let previousOccurrence = occurrence(
                day: normalizedDay,
                year: previousYear,
                month: previousMonthValue,
                calendar: calendar
              ) else {
            return nil
        }

        return BillingScheduleStatus(
            previousDate: previousOccurrence,
            nextDate: currentOccurrence,
            referenceDate: startOfReferenceDate,
            calendar: calendar
        )
    }

    static func yearlyStatus(
        month: Int,
        day: Int,
        referenceDate: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> BillingScheduleStatus? {
        guard let normalizedMonth = normalizedMonth(month),
              let normalizedDay = normalizedDay(day) else {
            return nil
        }

        let startOfReferenceDate = calendar.startOfDay(for: referenceDate)
        let referenceYear = calendar.component(.year, from: startOfReferenceDate)

        guard let currentOccurrence = occurrence(
            month: normalizedMonth,
            day: normalizedDay,
            year: referenceYear,
            calendar: calendar
        ) else {
            return nil
        }

        if currentOccurrence <= startOfReferenceDate {
            guard let nextOccurrence = occurrence(
                month: normalizedMonth,
                day: normalizedDay,
                year: referenceYear + 1,
                calendar: calendar
            ) else {
                return nil
            }

            return BillingScheduleStatus(
                previousDate: currentOccurrence,
                nextDate: nextOccurrence,
                referenceDate: startOfReferenceDate,
                calendar: calendar
            )
        }

        guard let previousOccurrence = occurrence(
            month: normalizedMonth,
            day: normalizedDay,
            year: referenceYear - 1,
            calendar: calendar
        ) else {
            return nil
        }

        return BillingScheduleStatus(
            previousDate: previousOccurrence,
            nextDate: currentOccurrence,
            referenceDate: startOfReferenceDate,
            calendar: calendar
        )
    }

    private static func occurrence(
        day: Int,
        year: Int,
        month: Int,
        calendar: Calendar
    ) -> Date? {
        let resolvedDay = clampedDay(day, year: year, month: month, calendar: calendar)
        let components = DateComponents(year: year, month: month, day: resolvedDay)
        return calendar.date(from: components)
    }

    private static func occurrence(
        month: Int,
        day: Int,
        year: Int,
        calendar: Calendar
    ) -> Date? {
        let resolvedDay = clampedDay(day, year: year, month: month, calendar: calendar)
        let components = DateComponents(year: year, month: month, day: resolvedDay)
        return calendar.date(from: components)
    }

    // Clamp recurring day values to the last valid day of the target month.
    private static func clampedDay(
        _ day: Int,
        year: Int,
        month: Int,
        calendar: Calendar
    ) -> Int {
        min(day, daysInMonth(year: year, month: month, calendar: calendar))
    }

    private static func daysInMonth(
        year: Int,
        month: Int,
        calendar: Calendar
    ) -> Int {
        let components = DateComponents(year: year, month: month)

        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return maximumDay(in: month)
        }

        return range.count
    }
}

extension Card {
    var normalizedWithdrawalDay: Int? {
        BillingScheduleCalculator.normalizedDay(withdrawalDay)
    }

    var withdrawalDayText: String? {
        guard let normalizedWithdrawalDay else {
            return nil
        }

        return "\(normalizedWithdrawalDay)日"
    }

    var nextWithdrawalStatus: BillingScheduleStatus? {
        guard let normalizedWithdrawalDay else {
            return nil
        }

        return BillingScheduleCalculator.monthlyStatus(day: normalizedWithdrawalDay)
    }
}

extension SubscriptionItem {
    var normalizedBillingDay: Int? {
        BillingScheduleCalculator.normalizedDay(billingDay)
    }

    var normalizedBillingMonth: Int? {
        BillingScheduleCalculator.normalizedMonth(billingMonth)
    }

    var billingScheduleText: String? {
        switch billingCycle {
        case .monthly:
            guard let normalizedBillingDay else {
                return nil
            }

            return "毎月\(normalizedBillingDay)日"
        case .yearly:
            guard let normalizedBillingMonth,
                  let normalizedBillingDay else {
                return nil
            }

            return "毎年\(normalizedBillingMonth)月\(normalizedBillingDay)日"
        }
    }

    var nextBillingStatus: BillingScheduleStatus? {
        switch billingCycle {
        case .monthly:
            guard let normalizedBillingDay else {
                return nil
            }

            return BillingScheduleCalculator.monthlyStatus(day: normalizedBillingDay)
        case .yearly:
            guard let normalizedBillingMonth,
                  let normalizedBillingDay else {
                return nil
            }

            return BillingScheduleCalculator.yearlyStatus(
                month: normalizedBillingMonth,
                day: normalizedBillingDay
            )
        }
    }
}
