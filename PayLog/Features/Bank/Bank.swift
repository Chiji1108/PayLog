//
//  Bank.swift
//  PayLog
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import Foundation
import SwiftData

@Model
final class Bank {
    var name: String = ""
    var branchName: String?
    var accountNumber: String?
    var notes: String?
    var isActive: Bool = true
    var sortOrder: Int = 0
    var createdAt: Date = Date.now
    @Relationship(deleteRule: .nullify, inverse: \Card.bank) var cards: [Card]?
    @Relationship(deleteRule: .nullify, inverse: \SubscriptionItem.bank) var subscriptions: [SubscriptionItem]?

    init(
        name: String,
        branchName: String? = nil,
        accountNumber: String? = nil,
        notes: String? = nil,
        isActive: Bool = true,
        sortOrder: Int = 0,
        createdAt: Date = Date.now
    ) {
        self.name = name
        self.branchName = branchName
        self.accountNumber = accountNumber
        self.notes = notes
        self.isActive = isActive
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}
