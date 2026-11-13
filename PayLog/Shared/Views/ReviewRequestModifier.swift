//
//  ReviewRequestModifier.swift
//  PayLog
//
//  Created by Codex on 2026/03/28.
//

import SwiftUI
import SwiftData
import StoreKit

/// 使い続けている人に、アプリを開いたときに App Store の評価を頼む。
/// 登録を終えたあとは見るだけになる人が多いので、項目の追加ではなく、アプリを開いたことをきっかけにする。
private struct ReviewRequestModifier: ViewModifier {
    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @AppStorage(ReviewRequestPolicy.firstLaunchTimestampKey) private var firstLaunchTimestamp = 0.0
    @AppStorage(ReviewRequestPolicy.lastRequestedVersionKey) private var lastRequestedVersion = ""

    func body(content: Content) -> some View {
        content
            // 待っている間にアプリを離れたら、頼むのをやめる
            .task(id: scenePhase) {
                guard scenePhase == .active, !ProcessInfo.isRunningForXcodePreviews, !ProcessInfo.isTakingScreenshots else {
                    return
                }

                if firstLaunchTimestamp == 0 {
                    firstLaunchTimestamp = Date.now.timeIntervalSince1970
                }

                guard ReviewRequestPolicy.isEligible(
                    firstLaunchTimestamp: firstLaunchTimestamp,
                    itemCount: itemCount,
                    lastRequestedVersion: lastRequestedVersion,
                    currentVersion: currentVersion
                ) else {
                    return
                }

                do {
                    try await Task.sleep(for: ReviewRequestPolicy.delay)
                } catch {
                    return
                }

                lastRequestedVersion = currentVersion
                requestReview()
            }
    }

    private var itemCount: Int {
        count(SubscriptionItem.self) + count(Card.self) + count(Bank.self) + count(ElectronicMoney.self)
    }

    private func count<Model: PersistentModel>(_ model: Model.Type) -> Int {
        (try? modelContext.fetchCount(FetchDescriptor<Model>())) ?? 0
    }

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
}

extension View {
    func reviewRequest() -> some View {
        modifier(ReviewRequestModifier())
    }
}
