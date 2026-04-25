//
//  ElectronicMoney.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import Foundation
import SwiftData

@Model
final class ElectronicMoney {
    var name: String
    var notes: String?
    var isActive: Bool
    var createdAt: Date
    var card: Card

    init(name: String, notes: String? = nil, card: Card, isActive: Bool = true, createdAt: Date = .now) {
        self.name = name
        self.notes = notes
        self.card = card
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
