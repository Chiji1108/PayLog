//
//  DisplaySortable.swift
//  SubscriptionManager
//
//  Created by Codex on 2026/03/28.
//

import Foundation

protocol DisplaySortable: Activatable {
    var name: String { get }
    var createdAt: Date { get }
}

extension Sequence where Element: DisplaySortable {
    func sortedForDisplay() -> [Element] {
        sorted { lhs, rhs in
            if lhs.isActive != rhs.isActive {
                return lhs.isActive && !rhs.isActive
            }

            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt > rhs.createdAt
            }

            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }
}

extension Bank: DisplaySortable {}
extension Card: DisplaySortable {}
extension ElectronicMoney: DisplaySortable {}
extension SubscriptionItem: DisplaySortable {}
