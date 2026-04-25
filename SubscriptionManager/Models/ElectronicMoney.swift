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
    var isActive: Bool
    var card: Card

    init(name: String, card: Card, isActive: Bool = true) {
        self.name = name
        self.card = card
        self.isActive = isActive
    }
}
