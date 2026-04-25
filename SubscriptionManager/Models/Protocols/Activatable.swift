//
//  Activatable.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

protocol Activatable {
    var isActive: Bool { get }
}

extension Activatable {
    var statusText: String {
        isActive ? "利用中" : "停止中"
    }
}

extension Bank: Activatable {}
extension Card: Activatable {}
extension ElectronicMoney: Activatable {}
extension SubscriptionItem: Activatable {}
