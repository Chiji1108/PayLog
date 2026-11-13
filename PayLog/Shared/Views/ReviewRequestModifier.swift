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
            // アプリを開くたびに1回。通知センターや許可のダイアログを閉じただけ（一時的に操作を受け付けない状態からの復帰）では、やり直さない
            .task(id: scenePhase == .background) {
                guard scenePhase != .background, !ProcessInfo.isRunningForXcodePreviews, !ProcessInfo.isTakingScreenshots else {
                    return
                }

                if firstLaunchTimestamp == 0 {
                    firstLaunchTimestamp = Date.now.timeIntervalSince1970
                }

                // 待っている間にアプリを離れたら、頼むのをやめる
                do {
                    try await Task.sleep(for: ReviewRequestPolicy.delay)
                } catch {
                    return
                }

                // 複数のウインドウから重ねて頼まないよう、待ったあとで判定する
                guard ReviewRequestPolicy.isEligible(
                    firstLaunchTimestamp: firstLaunchTimestamp,
                    itemCount: itemCount,
                    lastRequestedVersion: lastRequestedVersion,
                    currentVersion: currentVersion
                ) else {
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
