//
//  SubscriptionInsights.swift
//  PayLog
//
//  Created by Codex on 2026/03/28.
//

import Foundation
import SwiftData

struct SubscriptionInsightSummary {
    let monthlyTotal: Decimal
    let yearlyTotal: Decimal
    let dailyTotal: Decimal
    let rankedSubscriptions: [SubscriptionRankedItem]
    let paymentMethodGroups: [SubscriptionPaymentMethodGroup]
    let missingCurrencyCounts: [SubscriptionCurrency: Int]
    let totalSubscriptionCount: Int
    let convertedSubscriptionCount: Int

    var hasMissingRates: Bool {
        !missingCurrencyCounts.isEmpty
    }

    func total(for period: SubscriptionInsightPeriod) -> Decimal {
        switch period {
        case .day:
            dailyTotal
        case .month:
            monthlyTotal
        case .year:
            yearlyTotal
        }
    }
}

struct SubscriptionRankedItem: Identifiable {
    let subscription: SubscriptionItem
    let dailyAmount: Decimal
    let monthlyAmount: Decimal
    let yearlyAmount: Decimal

    var id: PersistentIdentifier {
        subscription.persistentModelID
    }

    func amount(for period: SubscriptionInsightPeriod) -> Decimal {
        switch period {
        case .day:
            dailyAmount
        case .month:
            monthlyAmount
        case .year:
            yearlyAmount
        }
    }
}

struct SubscriptionPaymentMethodGroup: Identifiable {
    let paymentMethod: SubscriptionPaymentMethod
    let items: [SubscriptionConvertedItem]
    let subgroups: [SubscriptionPaymentSourceGroup]

    var id: SubscriptionPaymentMethod { paymentMethod }

    var totalSubscriptionCount: Int { items.count }
    var convertedSubscriptionCount: Int { items.filter(\.isConverted).count }

    func total(for period: SubscriptionInsightPeriod) -> Decimal {
        items.reduce(into: .zero) { partialResult, item in
            partialResult += item.amount(for: period) ?? .zero
        }
    }
}

struct SubscriptionPaymentSourceGroup: Identifiable {
    let id: String
    let title: String
    let items: [SubscriptionConvertedItem]

    var totalSubscriptionCount: Int { items.count }
    var convertedSubscriptionCount: Int { items.filter(\.isConverted).count }

    func total(for period: SubscriptionInsightPeriod) -> Decimal {
        items.reduce(into: .zero) { partialResult, item in
            partialResult += item.amount(for: period) ?? .zero
        }
    }
}

struct SubscriptionConvertedItem: Identifiable {
    let subscription: SubscriptionItem
    let dailyAmount: Decimal?
    let monthlyAmount: Decimal?
    let yearlyAmount: Decimal?

    var id: PersistentIdentifier {
        subscription.persistentModelID
    }

    var isConverted: Bool {
        yearlyAmount != nil
    }

    func amount(for period: SubscriptionInsightPeriod) -> Decimal? {
        switch period {
        case .day:
            dailyAmount
        case .month:
            monthlyAmount
        case .year:
            yearlyAmount
        }
    }
}

enum SubscriptionInsightPeriod: String, CaseIterable, Identifiable {
    case day
    case month
    case year

    var id: String { rawValue }

    var label: String {
        switch self {
        case .day:
            "日"
        case .month:
            "月"
        case .year:
            "年"
        }
    }

    var totalTitle: String {
        switch self {
        case .day:
            "日割り換算"
        case .month:
            "月額換算"
        case .year:
            "年額換算"
        }
    }

    var rankingTitle: String {
        switch self {
        case .day:
            "日割り換算で高い順"
        case .month:
            "月額換算で高い順"
        case .year:
            "年額換算で高い順"
        }
    }

    var shareUnitLabel: String {
        switch self {
        case .day:
            "日"
        case .month:
            "月"
        case .year:
            "年"
        }
    }
}

enum SubscriptionInsightSettings {
    private static let yenRatesKey = "subscriptionInsights.yenRates"

    static func loadYenRates() -> [SubscriptionCurrency: Decimal] {
        guard
            let data = UserDefaults.standard.data(forKey: yenRatesKey),
            let storedRates = try? JSONDecoder().decode([String: Double].self, from: data)
        else {
            return [:]
        }

        return storedRates.reduce(into: [:]) { partialResult, entry in
            guard let currency = SubscriptionCurrency(rawValue: entry.key), entry.value > 0 else {
                return
            }

            partialResult[currency] = Decimal(entry.value)
        }
    }

    static func saveYenRates(_ rates: [SubscriptionCurrency: Decimal]) {
        let storedRates = rates.reduce(into: [String: Double]()) { partialResult, entry in
            guard entry.value > 0 else {
                return
            }

            partialResult[entry.key.rawValue] = NSDecimalNumber(decimal: entry.value).doubleValue
        }

        guard let data = try? JSONEncoder().encode(storedRates) else {
            return
        }

        UserDefaults.standard.set(data, forKey: yenRatesKey)
    }
}

enum SubscriptionInsightCalculator {
    private static let monthsPerYear = Decimal(12)
    private static let daysPerYear = Decimal(365)

    static func summary(
        subscriptions: [SubscriptionItem],
        yenRates: [SubscriptionCurrency: Decimal]
    ) -> SubscriptionInsightSummary {
        let activeSubscriptions = subscriptions.filter(\.isActive)
        var yearlyTotal = Decimal.zero
        var rankedSubscriptions: [SubscriptionRankedItem] = []
        var convertedItems: [SubscriptionConvertedItem] = []
        var missingCurrencyCounts: [SubscriptionCurrency: Int] = [:]

        for subscription in activeSubscriptions {
            guard let yearlyAmount = convertedYearlyAmount(
                for: subscription,
                yenRates: yenRates
            ) else {
                convertedItems.append(
                    SubscriptionConvertedItem(
                        subscription: subscription,
                        dailyAmount: nil,
                        monthlyAmount: nil,
                        yearlyAmount: nil
                    )
                )
                missingCurrencyCounts[subscription.currency, default: 0] += 1
                continue
            }

            let dailyAmount = yearlyAmount / daysPerYear
            let monthlyAmount = yearlyAmount / monthsPerYear
            yearlyTotal += yearlyAmount
            rankedSubscriptions.append(
                SubscriptionRankedItem(
                    subscription: subscription,
                    dailyAmount: dailyAmount,
                    monthlyAmount: monthlyAmount,
                    yearlyAmount: yearlyAmount
                )
            )
            convertedItems.append(
                SubscriptionConvertedItem(
                    subscription: subscription,
                    dailyAmount: dailyAmount,
                    monthlyAmount: monthlyAmount,
                    yearlyAmount: yearlyAmount
                )
            )
        }

        rankedSubscriptions.sort { lhs, rhs in
            if lhs.monthlyAmount != rhs.monthlyAmount {
                return lhs.monthlyAmount > rhs.monthlyAmount
            }

            return lhs.subscription.name.localizedStandardCompare(rhs.subscription.name) == .orderedAscending
        }

        return SubscriptionInsightSummary(
            monthlyTotal: yearlyTotal / monthsPerYear,
            yearlyTotal: yearlyTotal,
            dailyTotal: yearlyTotal / daysPerYear,
            rankedSubscriptions: rankedSubscriptions,
            paymentMethodGroups: paymentMethodGroups(from: convertedItems),
            missingCurrencyCounts: missingCurrencyCounts,
            totalSubscriptionCount: activeSubscriptions.count,
            convertedSubscriptionCount: rankedSubscriptions.count
        )
    }

    static func requiredYenRateCurrencies(
        subscriptions: [SubscriptionItem]
    ) -> [SubscriptionCurrency] {
        let currencies = Set(
            subscriptions
                .filter(\.isActive)
                .map(\.currency)
                .filter { $0 != .jpy }
        )

        return SubscriptionCurrency.allCases.filter { currencies.contains($0) }
    }

    private static func convertedYearlyAmount(
        for subscription: SubscriptionItem,
        yenRates: [SubscriptionCurrency: Decimal]
    ) -> Decimal? {
        if subscription.currency == .jpy {
            return subscription.yearlyAmount
        }

        guard let sourceRate = yenRates[subscription.currency], sourceRate > 0 else {
            return nil
        }

        return subscription.yearlyAmount * sourceRate
    }

    private static func paymentMethodGroups(
        from items: [SubscriptionConvertedItem]
    ) -> [SubscriptionPaymentMethodGroup] {
        SubscriptionPaymentMethod.allCases.compactMap { method in
            let methodItems = items.filter { $0.subscription.paymentMethod == method }
            guard !methodItems.isEmpty else {
                return nil
            }

            return SubscriptionPaymentMethodGroup(
                paymentMethod: method,
                items: sorted(items: methodItems),
                subgroups: paymentSourceGroups(for: method, items: methodItems)
            )
        }
    }

    private static func paymentSourceGroups(
        for paymentMethod: SubscriptionPaymentMethod,
        items: [SubscriptionConvertedItem]
    ) -> [SubscriptionPaymentSourceGroup] {
        switch paymentMethod {
        case .card:
            return groupedByCard(items)
        case .bankAccount:
            return groupedByBank(items)
        case .invoice, .onSite, .unspecified:
            return []
        }
    }

    private static func groupedByCard(
        _ items: [SubscriptionConvertedItem]
    ) -> [SubscriptionPaymentSourceGroup] {
        let groups = Dictionary(grouping: items) { item in
            item.subscription.card
        }

        return groups
            .map { card, groupItems in
                SubscriptionPaymentSourceGroup(
                    id: "card-\(card.map { String(describing: $0.persistentModelID) } ?? "none")",
                    title: card?.name ?? "カード未設定",
                    items: sorted(items: groupItems)
                )
            }
            .sorted { lhs, rhs in
                lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
            }
    }

    private static func groupedByBank(
        _ items: [SubscriptionConvertedItem]
    ) -> [SubscriptionPaymentSourceGroup] {
        let groups = Dictionary(grouping: items) { item in
            item.subscription.bank
        }

        return groups
            .map { bank, groupItems in
                SubscriptionPaymentSourceGroup(
                    id: "bank-\(bank.map { String(describing: $0.persistentModelID) } ?? "none")",
                    title: bank?.name ?? "口座未設定",
                    items: sorted(items: groupItems)
                )
            }
            .sorted { lhs, rhs in
                lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
            }
    }

    private static func sorted(
        items: [SubscriptionConvertedItem]
    ) -> [SubscriptionConvertedItem] {
        items.sorted { lhs, rhs in
            let lhsAmount = lhs.monthlyAmount ?? .zero
            let rhsAmount = rhs.monthlyAmount ?? .zero

            if lhsAmount != rhsAmount {
                return lhsAmount > rhsAmount
            }

            return lhs.subscription.name.localizedStandardCompare(rhs.subscription.name) == .orderedAscending
        }
    }
}

extension SubscriptionBillingFrequency {
    var yearlyMultiplier: Decimal {
        switch unit {
        case .week:
            Decimal(52) / Decimal(interval)
        case .month:
            Decimal(12) / Decimal(interval)
        case .year:
            Decimal(1) / Decimal(interval)
        }
    }
}

extension SubscriptionItem {
    var yearlyAmount: Decimal {
        amount * billingFrequency.yearlyMultiplier
    }
}
