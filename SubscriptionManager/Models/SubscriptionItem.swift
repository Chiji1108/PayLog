//
//  SubscriptionItem.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import Foundation
import SwiftData

enum SubscriptionBillingCycle: String, CaseIterable, Codable, Identifiable {
    case monthly
    case yearly

    var id: Self { self }

    var label: String {
        switch self {
        case .monthly:
            "月"
        case .yearly:
            "年"
        }
    }

    var amountSuffix: String {
        switch self {
        case .monthly:
            "月"
        case .yearly:
            "年"
        }
    }

    func formattedAmount(_ amount: Int) -> String {
        let amountText = amount.formatted(.currency(code: "JPY").precision(.fractionLength(0)))
        return "\(amountText) / \(amountSuffix)"
    }
}

enum SubscriptionPaymentMethod: String, CaseIterable, Codable, Identifiable {
    case card
    case bankAccount

    var id: Self { self }

    var label: String {
        switch self {
        case .card:
            "カード"
        case .bankAccount:
            "口座振替"
        }
    }
}

@Model
final class SubscriptionItem {
    var name: String = ""
    var amount: Int = 0
    var billingDay: Int?
    var billingMonth: Int?
    private var billingCycleRawValue: String = SubscriptionBillingCycle.monthly.rawValue
    private var paymentMethodRawValue: String?
    var notes: String?
    var isActive: Bool = true
    var createdAt: Date = Date.now
    var card: Card?
    var bank: Bank?

    var billingCycle: SubscriptionBillingCycle {
        get { SubscriptionBillingCycle(rawValue: billingCycleRawValue) ?? .monthly }
        set { billingCycleRawValue = newValue.rawValue }
    }

    var paymentMethod: SubscriptionPaymentMethod {
        get {
            if let paymentMethodRawValue,
               let paymentMethod = SubscriptionPaymentMethod(rawValue: paymentMethodRawValue) {
                return paymentMethod
            }

            return bank == nil ? .card : .bankAccount
        }
        set { paymentMethodRawValue = newValue.rawValue }
    }

    var amountWithBillingCycleText: String {
        billingCycle.formattedAmount(amount)
    }

    init(
        name: String,
        amount: Int,
        billingDay: Int? = nil,
        billingMonth: Int? = nil,
        billingCycle: SubscriptionBillingCycle = .monthly,
        paymentMethod: SubscriptionPaymentMethod = .card,
        notes: String? = nil,
        card: Card? = nil,
        bank: Bank? = nil,
        isActive: Bool = true,
        createdAt: Date = .now
    ) {
        self.name = name
        self.amount = amount
        self.billingDay = billingDay
        self.billingMonth = billingCycle == .yearly ? billingMonth : nil
        self.billingCycleRawValue = billingCycle.rawValue
        self.paymentMethodRawValue = paymentMethod.rawValue
        self.notes = notes
        self.card = paymentMethod == .card ? card : nil
        self.bank = paymentMethod == .bankAccount ? bank : nil
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
