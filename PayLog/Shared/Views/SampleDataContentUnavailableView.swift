//
//  SampleDataContentUnavailableView.swift
//  PayLog
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI

struct SampleDataContentUnavailableView: View {
    let title: String
    let systemImage: String
    let description: String
    let shouldConfirmReplacement: () -> Bool
    let applySampleData: () -> Void
    @State private var showingSampleDataConfirmation = false

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(description)
        } actions: {
            Button {
                if shouldConfirmReplacement() {
                    showingSampleDataConfirmation = true
                } else {
                    applySampleData()
                }
            } label: {
                Label("サンプルデータを入れる", systemImage: "sparkles")
            }
            .confirmationDialog(
                "サンプルデータで置き換えますか？",
                isPresented: $showingSampleDataConfirmation,
                titleVisibility: .visible
            ) {
                Button("置き換える", role: .destructive) {
                    applySampleData()
                }

                Button("キャンセル", role: .cancel) {
                }
            } message: {
                Text("既存の銀行口座・カード・電子マネー・固定費を削除し、サンプルデータに入れ替えます。")
            }
        }
    }
}

#Preview("Status Badge", traits: .sizeThatFitsLayout) {
    SampleDataContentUnavailableView(
        title: "テスト", systemImage: "gear", description: "テストだよ") {
        false
    } applySampleData: {
    }
}
