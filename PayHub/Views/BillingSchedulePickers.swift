//
//  BillingSchedulePickers.swift
//  SubscriptionManager
//
//  Created by Codex on 2026/03/28.
//

import SwiftUI

struct DayOfMonthPicker: View {
    let title: String
    @Binding var selection: Int?

    var body: some View {
        Picker(title, selection: $selection) {
            Text("未設定").tag(Optional<Int>.none)

            ForEach(1...31, id: \.self) { day in
                Text("\(day)日").tag(Optional(day))
            }
        }
    }
}

struct MonthDayPicker: View {
    let monthTitle: String
    let dayTitle: String
    @Binding var monthSelection: Int?
    @Binding var daySelection: Int?

    var body: some View {
        Picker(monthTitle, selection: $monthSelection) {
            Text("未設定").tag(Optional<Int>.none)

            ForEach(1...12, id: \.self) { month in
                Text("\(month)月").tag(Optional(month))
            }
        }
        .onChange(of: monthSelection) { _, newValue in
            guard let newValue else {
                daySelection = nil
                return
            }

            let maximumDay = BillingScheduleCalculator.maximumDay(in: newValue)

            if let daySelection, daySelection > maximumDay {
                self.daySelection = maximumDay
            }
        }

        Picker(dayTitle, selection: $daySelection) {
            Text("未設定").tag(Optional<Int>.none)

            ForEach(1...maximumDay, id: \.self) { day in
                Text("\(day)日").tag(Optional(day))
            }
        }
    }

    private var maximumDay: Int {
        BillingScheduleCalculator.maximumDay(in: monthSelection)
    }
}
