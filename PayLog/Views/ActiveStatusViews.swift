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
    private let isActive: Bool
    private let title: String
    private let trailingText: String?
    private let showIndicator: Bool
    private let indicator: ActiveStatusIndicator

    init(
        _ item: some Activatable,
        title: String,
        trailingText: String? = nil,
        showIndicator: Bool = true
    ) {
        self.isActive = item.isActive
        self.title = title
        self.trailingText = trailingText
        self.showIndicator = showIndicator
        self.indicator = ActiveStatusIndicator(item)
    }

    var body: some View {
        HStack {
            if showIndicator {
                indicator
            }

            Text(title)
                .font(.headline)
                .foregroundStyle(isActive ? .primary : .secondary)

            Spacer()

            if let trailingText {
                Text(trailingText)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ActiveStatusSectionHeader: View {
    private let isActive: Bool
    private let title: String

    init(isActive: Bool, title: String? = nil) {
        self.isActive = isActive
        self.title = title ?? (isActive ? "利用中" : "停止中")
    }

    var body: some View {
        HStack(spacing: 6) {
            ActiveStatusIndicator(isActive: isActive, statusText: title)
            Text(title)
        }
    }
}

struct ActiveStatusLabeledNavigationRow<Item: Activatable, Destination: View>: View {
    private let label: String
    private let item: Item
    private let title: String
    private let destination: Destination

    init(
        _ label: String,
        item: Item,
        title: String,
        @ViewBuilder destination: () -> Destination
    ) {
        self.label = label
        self.item = item
        self.title = title
        self.destination = destination()
    }

    var body: some View {
        NavigationLink {
            destination
        } label: {
            LabeledContent(label) {
                HStack(spacing: 6) {
                    ActiveStatusIndicator(item)
                    Text(title)
                }
            }
        }
    }
}

struct ActiveStatusLabeledContent<Item: Activatable>: View {
    private let label: String
    private let item: Item

    init(_ label: String = "状態", item: Item) {
        self.label = label
        self.item = item
    }

    var body: some View {
        LabeledContent(label) {
            HStack(spacing: 6) {
                ActiveStatusIndicator(item)
                Text(item.statusText)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct PreviewStatusItem: Activatable {
    let isActive: Bool
}

#Preview("Status Indicator", traits: .sizeThatFitsLayout) {
    ActiveStatusIndicator(PreviewStatusItem(isActive: true))
        .padding()
}

#Preview("Status Row", traits: .sizeThatFitsLayout) {
    ActiveStatusRow(
        PreviewStatusItem(isActive: true),
        title: "Netflix",
        trailingText: "¥1,490"
    )
    .padding()
}
