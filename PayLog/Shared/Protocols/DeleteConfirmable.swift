//
//  DeleteConfirmable.swift
//  PayLog
//
//  Created by Codex on 2026/03/28.
//

protocol DeleteConfirmable {
    static var deleteItemName: String { get }
    static var deleteConfirmationMessage: String? { get }
}

extension DeleteConfirmable {
    static var deleteConfirmationTitle: String {
        "この\(deleteItemName)を削除しますか？"
    }

    static var deleteButtonTitle: String {
        "削除"
    }
}

extension Bank: DeleteConfirmable {
    static var deleteItemName: String { "銀行口座" }
    static var deleteConfirmationMessage: String? { "紐付いているカードや口座振替の設定は未設定になります。" }
}

extension Card: DeleteConfirmable {
    static var deleteItemName: String { "カード" }
    static var deleteConfirmationMessage: String? { "紐付いている固定費や電子マネーのカード設定は未設定になります。" }
}

extension ElectronicMoney: DeleteConfirmable {
    static var deleteItemName: String { "電子マネー" }
    static var deleteConfirmationMessage: String? { "この操作は元に戻せません。" }
}

extension SubscriptionItem: DeleteConfirmable {
    static var deleteItemName: String { "固定費" }
    static var deleteConfirmationMessage: String? { "この操作は元に戻せません。" }
}
