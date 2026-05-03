//
//  Card.swift
//  PayLog
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import Foundation
import SwiftData

enum CardAnnualFeeSetting: String, CaseIterable, Codable, Identifiable {
    case unspecified
    case free
    case paid

    var id: Self { self }

    var label: String {
        switch self {
        case .unspecified:
            "未設定"
        case .free:
            "無料"
        case .paid:
            "有料"
        }
    }
}

@Model
final class Card {
    var name: String = ""
    var lastFourDigits: String?
    var closingDay: Int?
    var withdrawalDay: Int?
    var notes: String?
    var isActive: Bool = true
    var sortOrder: Int = 0
    var createdAt: Date = Date.now
    private var annualFeeSettingRawValue: String = CardAnnualFeeSetting.unspecified.rawValue
    var bank: Bank?
    @Relationship(deleteRule: .nullify, inverse: \SubscriptionItem.annualFeeCard) var annualFeeSubscription: SubscriptionItem?
    @Relationship(deleteRule: .nullify, inverse: \ElectronicMoney.card) var electronicMoneys: [ElectronicMoney]?
    @Relationship(deleteRule: .nullify, inverse: \SubscriptionItem.card) var subscriptions: [SubscriptionItem]?

    var annualFeeSetting: CardAnnualFeeSetting {
        get {
            if annualFeeSubscription != nil {
                return .paid
            }

            return CardAnnualFeeSetting(rawValue: annualFeeSettingRawValue) ?? .unspecified
        }
        set {
            annualFeeSettingRawValue = newValue.rawValue

            if newValue != .paid {
                annualFeeSubscription = nil
            }
        }
    }

    init(
        name: String,
        lastFourDigits: String? = nil,
        closingDay: Int? = nil,
        withdrawalDay: Int? = nil,
        notes: String? = nil,
        bank: Bank? = nil,
        annualFeeSetting: CardAnnualFeeSetting = .unspecified,
        annualFeeSubscription: SubscriptionItem? = nil,
        isActive: Bool = true,
        sortOrder: Int = 0,
        createdAt: Date = Date.now
    ) {
        self.name = name
        self.lastFourDigits = lastFourDigits
        self.closingDay = closingDay
        self.withdrawalDay = withdrawalDay
        self.notes = notes
        self.bank = bank
        self.annualFeeSettingRawValue = annualFeeSubscription == nil
            ? annualFeeSetting.rawValue
            : CardAnnualFeeSetting.paid.rawValue
        self.annualFeeSubscription = annualFeeSubscription
        self.isActive = isActive
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}
