//
//  OnboardingView.swift
//  PayLog
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI

struct OnboardingView: View {
    let onStart: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.accentColor.opacity(0.10),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 28) {
                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 8) {
                    Text("ようこそPayLogへ")
                        .font(.largeTitle.bold())
                }
                .padding(.bottom, 24)

                VStack(spacing: 16) {
                    FeatureCard(
                        systemImage: "square.grid.2x2",
                        title: "まとめて整理",
                        message: "固定費、カード、電子マネー、銀行口座をまとめて整理・記録できます。"
                    )

                    FeatureCard(
                        systemImage: "lock.shield",
                        title: "データ収集なし",
                        message: "入力したデータは外部サーバーへ送信されません。端末内とiCloud同期でのみ管理されます。"
                    )

                    FeatureCard(
                        systemImage: "icloud",
                        title: "iCloud自動同期",
                        message: "データはiCloudで自動的に同期されます。複数の端末から同じ情報を利用できます。"
                    )
                }

                Spacer(minLength: 0)

                Button(action: onStart) {
                    Text("始める")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
    }
}

private struct FeatureCard: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    OnboardingView(onStart: {})
}
