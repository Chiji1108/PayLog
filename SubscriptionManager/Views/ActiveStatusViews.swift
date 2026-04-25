//
//  ActiveStatusRow.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI

struct ActiveStatusIndicator: View {
    private let isActive: Bool
    private let statusText: String

    init(isActive: Bool, statusText: String) {
        self.isActive = isActive
        self.statusText = statusText
    }

    init(_ item: some Activatable) {
        self.isActive = item.isActive
        self.statusText = item.statusText
    }

    var body: some View {
        Image(systemName: "circle.fill")
            .font(.caption2)
            .foregroundStyle(isActive ? .green : .secondary)
            .accessibilityLabel(statusText)
    }
}

struct ActiveStatusRow: View {
    private let title: String
    private let trailingText: String?
    private let indicator: ActiveStatusIndicator

    init(_ item: some Activatable, title: String, trailingText: String? = nil) {
        self.title = title
        self.trailingText = trailingText
        self.indicator = ActiveStatusIndicator(item)
    }

    var body: some View {
        HStack {
            indicator

            Text(title)
                .font(.headline)

            Spacer()

            if let trailingText {
                Text(trailingText)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
