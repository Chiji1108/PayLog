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
    var name: String
    var lastFourDigits: String?
    var expiryDate: String?
    var notes: String?
    var isActive: Bool
    var createdAt: Date
    var bank: Bank
    @Relationship(deleteRule: .cascade, inverse: \ElectronicMoney.card) var electronicMoneys: [ElectronicMoney] = []
    @Relationship(deleteRule: .cascade, inverse: \SubscriptionItem.card) var subscriptions: [SubscriptionItem] = []

    init(
        name: String,
        lastFourDigits: String? = nil,
        expiryDate: String? = nil,
        notes: String? = nil,
        bank: Bank,
        isActive: Bool = true,
        createdAt: Date = .now
    ) {
        self.name = name
        self.lastFourDigits = lastFourDigits
        self.expiryDate = expiryDate
        self.notes = notes
        self.bank = bank
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
