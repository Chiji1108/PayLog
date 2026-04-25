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
    var isActive: Bool
    var bank: Bank
    @Relationship(deleteRule: .cascade, inverse: \ElectronicMoney.card) var electronicMoneys: [ElectronicMoney] = []
    @Relationship(deleteRule: .cascade, inverse: \SubscriptionItem.card) var subscriptions: [SubscriptionItem] = []

    init(name: String, bank: Bank, isActive: Bool = true) {
        self.name = name
        self.bank = bank
        self.isActive = isActive
    }
}
