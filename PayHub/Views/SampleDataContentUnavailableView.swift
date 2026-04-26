//
//  SampleDataContentUnavailableView.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI

struct SampleDataContentUnavailableView: View {
    let title: String
    let systemImage: String
    let description: String
    let addSampleData: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(description)
        } actions: {
            Button(action: addSampleData) {
                Label("サンプルデータを追加してみる", systemImage: "sparkles")
            }
        }
    }
}

#Preview("Status Badge", traits: .sizeThatFitsLayout) {
    SampleDataContentUnavailableView(
        title: "テスト", systemImage: "gear", description: "テストだよ") {
            () -> Void in
        }
}
