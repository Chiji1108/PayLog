//
//  BillingSchedulePickers.swift
//  PayLog
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
