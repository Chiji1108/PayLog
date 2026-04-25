//
//  DetailStatusSection.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI

struct DetailStatusSection: View {
    private let indicator: ActiveStatusIndicator
    private let statusText: String

    init(_ item: some Activatable) {
        self.indicator = ActiveStatusIndicator(item)
        self.statusText = item.statusText
    }

    var body: some View {
        Section("状態") {
            LabeledContent("現在") {
                HStack(spacing: 6) {
                    indicator
                    Text(statusText)
                }
            }
        }
    }
}
