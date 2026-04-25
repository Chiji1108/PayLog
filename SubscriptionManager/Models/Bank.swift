//
//  Bank.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import Foundation
import SwiftData

@Model
final class Bank {
    var name: String
    var isActive: Bool
    @Relationship(deleteRule: .cascade, inverse: \Card.bank) var cards: [Card] = []

    init(name: String, isActive: Bool = true) {
        self.name = name
        self.isActive = isActive
    }
}
