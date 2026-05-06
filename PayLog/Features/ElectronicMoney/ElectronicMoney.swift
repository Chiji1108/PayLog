//
//  ElectronicMoney.swift
//  PayLog
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import Foundation
import SwiftData

enum ElectronicMoneyFundingSource: String, CaseIterable, Codable, Identifiable {
    case card
    case bankAccount
    case cash
    case unspecified

    var id: Self { self }

    var label: String {
        switch self {
        case .card:
            "カード"
        case .bankAccount:
            "口座振替"
        case .cash:
            "現金"
        case .unspecified:
            "未設定"
        }
    }
}

@Model
final class ElectronicMoney {
    var name: String = ""
    var notes: String?
    var isActive: Bool = true
    var sortOrder: Int = 0
    var createdAt: Date = Date.now
    private var fundingSourceRawValue: String?
    var card: Card?
    var bank: Bank?

    var fundingSource: ElectronicMoneyFundingSource {
        get {
            if let fundingSourceRawValue,
               let fundingSource = ElectronicMoneyFundingSource(rawValue: fundingSourceRawValue) {
                return fundingSource
            }

            if bank != nil {
                return .bankAccount
            }

            if card != nil {
                return .card
            }

            return .unspecified
        }
        set { fundingSourceRawValue = newValue.rawValue }
    }

    init(
        name: String,
        notes: String? = nil,
        fundingSource: ElectronicMoneyFundingSource = .unspecified,
        card: Card? = nil,
        bank: Bank? = nil,
        isActive: Bool = true,
        sortOrder: Int = 0,
        createdAt: Date = Date.now
    ) {
        self.name = name
        self.notes = notes
        self.fundingSourceRawValue = fundingSource.rawValue
        self.card = fundingSource == .card ? card : nil
        self.bank = fundingSource == .bankAccount ? bank : nil
        self.isActive = isActive
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}
