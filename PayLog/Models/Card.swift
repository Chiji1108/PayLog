//
//  Card.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import Foundation
import SwiftData

@Model
final class Card {
    var name: String = ""
    var lastFourDigits: String?
    var closingDay: Int?
    var withdrawalDay: Int?
    var notes: String?
    var isActive: Bool = true
    var createdAt: Date = Date.now
    var bank: Bank?
    @Relationship(deleteRule: .nullify, inverse: \ElectronicMoney.card) var electronicMoneys: [ElectronicMoney]?
    @Relationship(deleteRule: .nullify, inverse: \SubscriptionItem.card) var subscriptions: [SubscriptionItem]?

    init(
        name: String,
        lastFourDigits: String? = nil,
        closingDay: Int? = nil,
        withdrawalDay: Int? = nil,
        notes: String? = nil,
        bank: Bank? = nil,
        isActive: Bool = true,
        createdAt: Date = Date.now
    ) {
        self.name = name
        self.lastFourDigits = lastFourDigits
        self.closingDay = closingDay
        self.withdrawalDay = withdrawalDay
        self.notes = notes
        self.bank = bank
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
