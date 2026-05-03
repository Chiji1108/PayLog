//
//  ElectronicMoney.swift
//  PayLog
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import Foundation
import SwiftData

@Model
final class ElectronicMoney {
    var name: String = ""
    var notes: String?
    var isActive: Bool = true
    var sortOrder: Int = 0
    var createdAt: Date = Date.now
    var card: Card?

    init(
        name: String,
        notes: String? = nil,
        card: Card? = nil,
        isActive: Bool = true,
        sortOrder: Int = 0,
        createdAt: Date = Date.now
    ) {
        self.name = name
        self.notes = notes
        self.card = card
        self.isActive = isActive
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}
