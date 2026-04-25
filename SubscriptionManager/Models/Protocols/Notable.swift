//
//  Notable.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import Foundation

protocol Notable {
    var notes: String? { get set }
}

extension Notable {
    var trimmedNotes: String? {
        guard let notes else {
            return nil
        }

        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedNotes.isEmpty ? nil : trimmedNotes
    }

    var hasNotes: Bool {
        trimmedNotes != nil
    }
}

extension Bank: Notable {}
extension Card: Notable {}
extension ElectronicMoney: Notable {}
extension SubscriptionItem: Notable {}
