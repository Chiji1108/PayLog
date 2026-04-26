//
//  FloatingBadge.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI

struct FloatingBadge<Content: View>: View {
    @ViewBuilder private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.background, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(.quaternary, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
    }
}

private struct FloatingBadgeModifier<Badge: View>: ViewModifier {
    private let badge: Badge

    init(@ViewBuilder badge: () -> Badge) {
        self.badge = badge()
    }

    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                badge
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .allowsHitTesting(false)
        }
    }
}

extension View {
    func floatingBadge<Badge: View>(@ViewBuilder _ badge: () -> Badge) -> some View {
        modifier(FloatingBadgeModifier(badge: badge))
    }
}

#Preview("Floating Badge", traits: .sizeThatFitsLayout) {
    FloatingBadge {
        HStack(spacing: 8) {
            Text("合計 ¥2,770 / 月")
        }
    }
    .padding()
}
