//
//  ActiveStatusIndicator.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI

struct ActiveStatusIndicator: View {
    let isActive: Bool
    let statusText: String

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
