//
//  BillingScheduleStatusSection.swift
//  SubscriptionManager
//
//  Created by Codex on 2026/03/28.
//

import SwiftUI

struct BillingScheduleProgressView: View {
    let scheduleLabel: String
    let status: BillingScheduleStatus?

    var body: some View {
        if let status {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "repeat")
                        Text(status.nextDate.formatted(.dateTime.year().month(.defaultDigits).day(.defaultDigits)))
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: true, vertical: false)

                    Spacer()

                    Text("あと\(status.daysUntilNext)日")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: status.progress)
                    .tint(.accentColor)
            }
            .padding(.vertical, 4)
        } else {
            Text("\(scheduleLabel)は未設定です")
                .foregroundStyle(.secondary)
        }
    }
}
