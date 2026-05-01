//
//  RelatedItemCreationPrompt.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI

struct RelatedItemCreationPrompt: View {
    let message: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message)
                .foregroundStyle(.secondary)

            Button(action: action) {
                Label(buttonTitle, systemImage: "plus")
            }
        }
        .padding(.vertical, 4)
    }
}
