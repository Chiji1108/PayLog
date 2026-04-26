//
//  CreationDated.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import Foundation

protocol CreationDated {
    var createdAt: Date { get }
}

extension Sequence where Element: Activatable & CreationDated {
    func sortedForDisplay() -> [Element] {
        sorted { lhs, rhs in
            if lhs.isActive != rhs.isActive {
                return lhs.isActive && !rhs.isActive
            }

            return lhs.createdAt > rhs.createdAt
        }
    }
}

extension Bank: CreationDated {}
extension Card: CreationDated {}
extension ElectronicMoney: CreationDated {}
extension SubscriptionItem: CreationDated {}
