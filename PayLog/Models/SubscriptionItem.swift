//
//  SubscriptionItem.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import Foundation
import SwiftData

enum SubscriptionBillingUnit: String, CaseIterable, Codable, Identifiable {
    case week
    case month
    case year

    var id: Self { self }

    var label: String {
        switch self {
        case .week:
            "週"
        case .month:
            "月"
        case .year:
            "年"
        }
    }

    var durationLabel: String {
        switch self {
        case .week:
            "週間"
        case .month:
            "ヶ月"
        case .year:
            "年"
        }
    }

    var amountSuffix: String {
        switch self {
        case .week:
            "週"
        case .month:
            "月"
        case .year:
            "年"
        }
    }

    var sortOrder: Int {
        switch self {
        case .week:
            0
        case .month:
            1
        case .year:
            2
        }
    }
}

struct SubscriptionBillingFrequency: Hashable, Identifiable, Comparable {
    let interval: Int
    let unit: SubscriptionBillingUnit

    init(interval: Int, unit: SubscriptionBillingUnit) {
        self.interval = max(interval, 1)
        self.unit = unit
    }

    var id: String {
        "\(unit.rawValue)-\(interval)"
    }

    var filterLabel: String {
        intervalDescription
    }

    var intervalDescription: String {
        "\(interval)\(unit.durationLabel)"
    }

    func formattedAmount(_ amount: Int) -> String {
        let amountText = amount.formatted(.currency(code: "JPY").precision(.fractionLength(0)))
        let suffix = interval == 1 ? unit.amountSuffix : "\(interval)\(unit.durationLabel)"
        return "\(amountText) / \(suffix)"
    }

    static func < (lhs: SubscriptionBillingFrequency, rhs: SubscriptionBillingFrequency) -> Bool {
        if lhs.unit.sortOrder == rhs.unit.sortOrder {
            return lhs.interval < rhs.interval
        }

        return lhs.unit.sortOrder < rhs.unit.sortOrder
    }
}

enum SubscriptionPaymentMethod: String, CaseIterable, Codable, Identifiable {
    case card
    case bankAccount
    case invoice
    case onSite
    case unspecified

    var id: Self { self }

    var label: String {
        switch self {
        case .card:
            "カード"
        case .bankAccount:
            "口座振替"
        case .invoice:
            "請求書払い"
        case .onSite:
            "現地払い"
        case .unspecified:
            "未設定"
        }
    }

    var billingCountdownLabel: String {
        switch self {
        case .onSite:
            "予定"
        case .card, .bankAccount, .invoice, .unspecified:
            "請求"
        }
    }
}

@Model
final class SubscriptionItem {
    var name: String = ""
    var amount: Int = 0
    var createdAt: Date = Date.now
    var billingInterval: Int = 1
    var billingAnchorDate: Date = Date.now
    private var billingUnitRawValue: String = SubscriptionBillingUnit.month.rawValue
    private var paymentMethodRawValue: String?
    var notes: String?
    var isActive: Bool = true
    var card: Card?
    var bank: Bank?
    var annualFeeCard: Card?

    var billingUnit: SubscriptionBillingUnit {
        get { SubscriptionBillingUnit(rawValue: billingUnitRawValue) ?? .month }
        set { billingUnitRawValue = newValue.rawValue }
    }

    var billingFrequency: SubscriptionBillingFrequency {
        SubscriptionBillingFrequency(interval: billingInterval, unit: billingUnit)
    }

    var paymentMethod: SubscriptionPaymentMethod {
        get {
            if let paymentMethodRawValue,
               let paymentMethod = SubscriptionPaymentMethod(rawValue: paymentMethodRawValue) {
                return paymentMethod
            }

            if bank != nil {
                return .bankAccount
            }

            if card != nil {
                return .card
            }

            return .unspecified
        }
        set { paymentMethodRawValue = newValue.rawValue }
    }

    var amountWithBillingCycleText: String {
        billingFrequency.formattedAmount(amount)
    }

    var billingCountdownLabel: String {
        paymentMethod.billingCountdownLabel
    }

    init(
        name: String,
        amount: Int,
        createdAt: Date = Date.now,
        billingInterval: Int = 1,
        billingUnit: SubscriptionBillingUnit = .month,
        billingAnchorDate: Date = .now,
        paymentMethod: SubscriptionPaymentMethod = .unspecified,
        notes: String? = nil,
        card: Card? = nil,
        bank: Bank? = nil,
        isActive: Bool = true
    ) {
        self.name = name
        self.amount = amount
        self.createdAt = createdAt
        self.billingInterval = max(billingInterval, 1)
        self.billingAnchorDate = Calendar.autoupdatingCurrent.startOfDay(for: billingAnchorDate)
        self.billingUnitRawValue = billingUnit.rawValue
        self.paymentMethodRawValue = paymentMethod.rawValue
        self.notes = notes
        self.card = paymentMethod == .card ? card : nil
        self.bank = paymentMethod == .bankAccount ? bank : nil
        self.isActive = isActive
    }
}
