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
    var expiryDate: String?
    var notes: String?
    var isActive: Bool = true
    var createdAt: Date = Date.now
    var bank: Bank?
    @Relationship(deleteRule: .nullify, inverse: \ElectronicMoney.card) var electronicMoneys: [ElectronicMoney]?
    @Relationship(deleteRule: .nullify, inverse: \SubscriptionItem.card) var subscriptions: [SubscriptionItem]?

    init(
        name: String,
        lastFourDigits: String? = nil,
        expiryDate: String? = nil,
        notes: String? = nil,
        bank: Bank? = nil,
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

    var formattedExpiryDate: String? {
        Self.formattedExpiryDate(from: expiryDate)
    }

    static func formattedExpiryDate(from expiryDate: String?) -> String? {
        guard let expiryDate, expiryDate.count == 4 else {
            return nil
        }

        let month = expiryDate.prefix(2)
        let year = expiryDate.suffix(2)
        return "\(month)/\(year)"
    }
}
