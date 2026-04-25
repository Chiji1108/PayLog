//
//  SubscriptionItem.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import Foundation
import SwiftData

@Model
final class SubscriptionItem {
    var name: String
    var monthlyAmount: Int
    var isActive: Bool
    var card: Card

    init(name: String, monthlyAmount: Int, card: Card, isActive: Bool = true) {
        self.name = name
        self.monthlyAmount = monthlyAmount
        self.card = card
        self.isActive = isActive
    }
}
