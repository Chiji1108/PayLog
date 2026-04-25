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
            "月額"
        case .yearly:
            "年額"
        }
    }
}

@Model
final class SubscriptionItem {
    var name: String
    var amount: Int
    private var billingCycleRawValue: String
    var notes: String?
    var isActive: Bool
    var createdAt: Date
    var card: Card

    var billingCycle: SubscriptionBillingCycle {
        get { SubscriptionBillingCycle(rawValue: billingCycleRawValue) ?? .monthly }
        set { billingCycleRawValue = newValue.rawValue }
    }

    init(
        name: String,
        amount: Int,
        billingCycle: SubscriptionBillingCycle = .monthly,
        notes: String? = nil,
        card: Card,
        isActive: Bool = true,
        createdAt: Date = .now
    ) {
        self.name = name
        self.amount = amount
        self.billingCycleRawValue = billingCycle.rawValue
        self.notes = notes
        self.card = card
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
