//
//  ReviewRequestPolicy.swift
//  PayLog
//
//  Created by Codex on 2026/03/28.
//

import Foundation

/// App Store の評価を頼んでよいかどうかの条件
enum ReviewRequestPolicy {
    static let firstLaunchTimestampKey = "reviewRequest.firstLaunchTimestamp"
    static let lastRequestedVersionKey = "reviewRequest.lastRequestedVersion"
    /// 使い始めてからこの日数がたつまでは頼まない
    static let eligibleDays = 7
    /// 登録した項目（固定費・カード・銀行口座・ウォレット）がこの数に届くまでは頼まない
    static let eligibleItemCount = 3
    /// アプリを開いた直後を避けるための待ち時間
    static let delay: Duration = .seconds(1.5)

    /// 頼むのはバージョンごとに1回まで。実際に表示するかは、さらに OS が決める（年に3回まで）。
    static func isEligible(
        firstLaunchTimestamp: Double,
        itemCount: Int,
        lastRequestedVersion: String,
        currentVersion: String,
        now: Date = .now
    ) -> Bool {
        guard firstLaunchTimestamp > 0, lastRequestedVersion != currentVersion else {
            return false
        }

        let firstLaunchDate = Date(timeIntervalSince1970: firstLaunchTimestamp)
        let daysSinceFirstLaunch = Calendar.autoupdatingCurrent
            .dateComponents([.day], from: firstLaunchDate, to: now)
            .day ?? 0

        return daysSinceFirstLaunch >= eligibleDays && itemCount >= eligibleItemCount
    }
}
