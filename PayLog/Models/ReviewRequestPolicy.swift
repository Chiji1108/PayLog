//
//  ReviewRequestPolicy.swift
//  PayLog
//
//  Created by Codex on 2026/03/28.
//

import Foundation

enum ReviewRequestPolicy {
    static let firstLaunchTimestampKey = "reviewRequest.firstLaunchTimestamp"
    static let hasRequestedReviewKey = "reviewRequest.hasRequestedReview"
    static let eligibleDays = 30
    static let reviewDelayNanoseconds: UInt64 = 1_500_000_000

    static func isEligible(
        firstLaunchTimestamp: Double,
        activeSubscriptionCount: Int,
        cardCount: Int,
        bankCount: Int,
        now: Date = .now
    ) -> Bool {
        guard firstLaunchTimestamp > 0 else {
            return false
        }

        let firstLaunchDate = Date(timeIntervalSince1970: firstLaunchTimestamp)
        let daysSinceFirstLaunch = Calendar.autoupdatingCurrent
            .dateComponents([.day], from: firstLaunchDate, to: now)
            .day ?? 0

        guard daysSinceFirstLaunch >= eligibleDays else {
            return false
        }

        guard activeSubscriptionCount >= 2 else {
            return false
        }

        return cardCount > 0 && bankCount > 0
    }
}
