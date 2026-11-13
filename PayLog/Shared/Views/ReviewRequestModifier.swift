//
//  ReviewRequestAfterCreationModifier.swift
//  PayLog
//
//  Created by Codex on 2026/03/28.
//

import SwiftUI
import SwiftData
import StoreKit

private struct ReviewRequestAfterCreationModifier: ViewModifier {
    @Environment(\.requestReview) private var requestReview
    @Query private var subscriptions: [SubscriptionItem]
    @Query private var cards: [Card]
    @Query private var banks: [Bank]
    @AppStorage(ReviewRequestPolicy.firstLaunchTimestampKey) private var firstLaunchTimestamp = 0.0
    @AppStorage(ReviewRequestPolicy.hasRequestedReviewKey) private var hasRequestedReview = false

    let trigger: Int

    func body(content: Content) -> some View {
        content
            .onChange(of: trigger) { _, _ in
                requestReviewIfEligible()
            }
    }

    private func requestReviewIfEligible() {
        guard !hasRequestedReview else {
            return
        }

        guard ReviewRequestPolicy.isEligible(
            firstLaunchTimestamp: firstLaunchTimestamp,
            activeSubscriptionCount: subscriptions.filter(\.isActive).count,
            cardCount: cards.count,
            bankCount: banks.count
        ) else {
            return
        }

        hasRequestedReview = true

        Task {
            try? await Task.sleep(nanoseconds: ReviewRequestPolicy.reviewDelayNanoseconds)
            requestReview()
        }
    }
}

extension View {
    func reviewRequestAfterCreation(trigger: Int) -> some View {
        modifier(ReviewRequestAfterCreationModifier(trigger: trigger))
    }
}
