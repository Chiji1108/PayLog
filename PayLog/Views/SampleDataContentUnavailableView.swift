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
    @State private var showingSampleDataConfirmation = false

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(description)
        } actions: {
            Button {
                showingSampleDataConfirmation = true
            } label: {
                Label("サンプルデータをまとめて追加", systemImage: "sparkles")
            }
            .confirmationDialog(
                "サンプルデータを追加しますか？",
                isPresented: $showingSampleDataConfirmation,
                titleVisibility: .visible
            ) {
                Button("追加する") {
                    addSampleData()
                }

                Button("キャンセル", role: .cancel) {
                }
            } message: {
                Text("銀行口座・カード・電子マネー・固定費のサンプルデータをまとめて追加します。")
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
