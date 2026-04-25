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
    var branchName: String?
    var accountNumber: String?
    var notes: String?
    var isActive: Bool
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \Card.bank) var cards: [Card] = []

    init(
        name: String,
        branchName: String? = nil,
        accountNumber: String? = nil,
        notes: String? = nil,
        isActive: Bool = true,
        createdAt: Date = .now
    ) {
        self.name = name
        self.branchName = branchName
        self.accountNumber = accountNumber
        self.notes = notes
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
