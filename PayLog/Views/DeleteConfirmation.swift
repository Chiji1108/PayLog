//
//  DeleteConfirmation.swift
//  PayHub
//
//  Created by Codex on 2026/03/28.
//

import SwiftUI

struct DeleteRequest<Item: DeleteConfirmable> {
    let item: Item
}

private struct DeleteConfirmationModifier<Item: DeleteConfirmable>: ViewModifier {
    @Binding var request: DeleteRequest<Item>?
    let onConfirm: (Item) -> Void

    func body(content: Content) -> some View {
        content.confirmationDialog(
            Item.deleteConfirmationTitle,
            isPresented: isPresented,
            titleVisibility: .visible
        ) {
            Button(Item.deleteButtonTitle, role: .destructive) {
                let item = request?.item
                request = nil

                guard let item else {
                    return
                }

                Task { @MainActor in
                    onConfirm(item)
                }
            }

            Button("キャンセル", role: .cancel) {
                request = nil
            }
        } message: {
            if let message = Item.deleteConfirmationMessage {
                Text(message)
            }
        }
    }

    private var isPresented: Binding<Bool> {
        Binding(
            get: { request != nil },
            set: { isPresented in
                if !isPresented {
                    request = nil
                }
            }
        )
    }
}

extension View {
    func deleteConfirmation<Item: DeleteConfirmable>(
        request: Binding<DeleteRequest<Item>?>,
        onConfirm: @escaping (Item) -> Void
    ) -> some View {
        modifier(DeleteConfirmationModifier(request: request, onConfirm: onConfirm))
    }
}
