//
//  SubscriptionInsightsView.swift
//  PayLog
//
//  Created by Codex on 2026/03/28.
//

import SwiftUI
import Charts
import SwiftData
import CoreTransferable
import UIKit

struct SubscriptionInsightsView: View {
    @Query private var subscriptions: [SubscriptionItem]
    @State private var yenRates = SubscriptionInsightSettings.loadYenRates()
    @State private var selectedPeriod: SubscriptionInsightPeriod = .month
    @State private var sharePhoto: SubscriptionInsightsSharePhoto?

    private let rateFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 4
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    var body: some View {
        List {
            if activeSubscriptions.isEmpty {
                Section {
                    ContentUnavailableView(
                        "固定費がまだありません",
                        systemImage: "chart.bar.xaxis",
                        description: Text("固定費を追加すると分析結果がここに表示されます。")
                    )
                }
            } else {
                if !trackedCurrencies.isEmpty {
                    Section {
                        ForEach(trackedCurrencies) { currency in
                            NavigationLink {
                                ExchangeRateEditorView(
                                    currency: currency,
                                    initialRate: yenRates[currency],
                                    formatter: rateFormatter
                                ) { rate in
                                    updateRate(rate, for: currency)
                                }
                            } label: {
                                LabeledContent(currency.label) {
                                    Text(rateValueText(for: currency))
                                }
                            }
                        }
                    } header: {
                        Text("為替レート")
                    } footer: {
                        if summary.hasMissingRates {
                            Text("未設定の通貨は、合計や高い順の計算から除外されます。")
                        }
                    }
                }
                
                Section {
                    Picker("換算単位", selection: $selectedPeriod) {
                        ForEach(SubscriptionInsightPeriod.allCases) { period in
                            Text(period.label).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("換算単位")
                }
                
                Section {
                    paymentSourceChartSection
                } header: {
                    Text("集計")
                } footer: {
                    if summary.hasMissingRates {
                        Text(totalFooterText)
                    }
                }

                Section("ランキング") {
                    if summary.rankedSubscriptions.isEmpty {
                        ContentUnavailableView(
                            "換算できる固定費がありません",
                            systemImage: "list.number",
                            description: Text("為替レートを設定するとランキングを表示できます。")
                        )
                    } else {
                        ForEach(Array(summary.rankedSubscriptions.enumerated()), id: \.element.id) { index, item in
                            Label {
                                LabeledContent {
                                    Text(
                                        SubscriptionCurrency.jpy.formattedAmount(
                                            item.amount(for: selectedPeriod)
                                        )
                                    )
                                        .monospacedDigit()
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.subscription.name)
                                        Text(item.subscription.amountWithBillingCycleText)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            } icon: {
                                Text("\(index + 1)")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("固定費サマリー")
        .task(id: shareSnapshotIdentifier) {
            updateShareImage()
        }
        .toolbar {
            if !activeSubscriptions.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    if let sharePhoto {
                        ShareLink(
                            item: sharePhoto,
                            subject: Text("固定費サマリー"),
                            preview: SharePreview(
                                sharePhoto.title,
                                image: sharePhoto.image
                            )
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("固定費サマリーを共有")
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("固定費サマリー画像を準備中")
                    }
                }
            }
        }
    }

    private var activeSubscriptions: [SubscriptionItem] {
        subscriptions.filter(\.isActive)
    }

    private var summary: SubscriptionInsightSummary {
        SubscriptionInsightCalculator.summary(
            subscriptions: subscriptions,
            yenRates: yenRates
        )
    }

    private var trackedCurrencies: [SubscriptionCurrency] {
        SubscriptionInsightCalculator.requiredYenRateCurrencies(subscriptions: subscriptions)
    }

    private var paymentSourceChartItems: [PaymentSourceChartItem] {
        var items: [PaymentSourceChartItem] = []

        for group in summary.paymentMethodGroups {
            if group.subgroups.isEmpty {
                let amount = group.total(for: selectedPeriod)
                guard amount > 0 else {
                    continue
                }

                items.append(
                    PaymentSourceChartItem(
                        id: group.paymentMethod.rawValue,
                        title: group.paymentMethod.label,
                        amount: amount,
                        convertedCount: group.convertedSubscriptionCount,
                        totalCount: group.totalSubscriptionCount
                    )
                )
            } else {
                for subgroup in group.subgroups {
                    let amount = subgroup.total(for: selectedPeriod)
                    guard amount > 0 else {
                        continue
                    }

                    items.append(
                        PaymentSourceChartItem(
                            id: subgroup.id,
                            title: subgroup.title,
                            amount: amount,
                            convertedCount: subgroup.convertedSubscriptionCount,
                            totalCount: subgroup.totalSubscriptionCount
                        )
                    )
                }
            }
        }

        return items.sorted { lhs, rhs in
            if lhs.amount != rhs.amount {
                return lhs.amount > rhs.amount
            }

            return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        }
    }

    private var totalFooterText: String {
        if summary.totalSubscriptionCount == 0 {
            return "アクティブな固定費を集計します。"
        }

        if summary.hasMissingRates {
            let unconvertedCount = summary.totalSubscriptionCount - summary.convertedSubscriptionCount
            return "為替レート未設定のため、未換算の固定費が \(unconvertedCount) 件あります。"
        }

        return "アクティブな固定費 \(summary.totalSubscriptionCount) 件をすべて換算しています。"
    }

    private var shareSnapshotIdentifier: String {
        let itemsToken = paymentSourceChartItems
            .map { "\($0.id):\($0.amount):\($0.convertedCount):\($0.totalCount)" }
            .joined(separator: "|")

        return [
            selectedPeriod.rawValue,
            "\(summary.total(for: selectedPeriod))",
            "\(summary.totalSubscriptionCount)",
            "\(summary.convertedSubscriptionCount)",
            "\(summary.hasMissingRates)",
            itemsToken
        ].joined(separator: "#")
    }

    private var shareCardFooterText: String? {
        guard summary.hasMissingRates else {
            return nil
        }

        return totalFooterText
    }

    @ViewBuilder
    private var paymentSourceChartSection: some View {
        if paymentSourceChartItems.isEmpty {
            ContentUnavailableView(
                "換算できる固定費がありません",
                systemImage: "chart.pie",
                description: Text("為替レートを設定すると支払い元ごとの構成を表示できます。")
            )
        } else {
            VStack(alignment: .leading, spacing: 16) {
                VStack(spacing: 4) {
                    LabeledContent(selectedPeriod.totalTitle) {
                        Text(SubscriptionCurrency.jpy.formattedAmount(summary.total(for: selectedPeriod)))
                            .monospacedDigit()
                    }

                    Chart(paymentSourceChartItems) { item in
                        BarMark(
                            x: .value("金額", item.doubleAmount),
                            y: .value("区分", "支払い元"),
                        )
                        .foregroundStyle(by: .value("支払い元", item.title))
                        .accessibilityLabel(item.title)
                        .accessibilityValue(SubscriptionCurrency.jpy.formattedAmount(item.amount))
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(height: 80)
                }
            }
        }
    }

    private func rateValueText(for currency: SubscriptionCurrency) -> String {
        guard let rate = yenRates[currency] else {
            return "未設定"
        }

        let rateText = rateFormatter.string(from: NSDecimalNumber(decimal: rate)) ?? ""
        return "\(rateText) 円"
    }

    private func updateRate(_ rate: Decimal?, for currency: SubscriptionCurrency) {
        if let rate, rate > 0 {
            yenRates[currency] = rate
        } else {
            yenRates.removeValue(forKey: currency)
        }

        SubscriptionInsightSettings.saveYenRates(yenRates)
    }

    @MainActor
    private func updateShareImage() {
        let cardView = SubscriptionInsightsShareCard(
            appIcon: shareAppIconImage,
            selectedPeriodTitle: selectedPeriod.totalTitle,
            totalAmountText: SubscriptionCurrency.jpy.formattedAmount(summary.total(for: selectedPeriod)),
            chartItems: paymentSourceChartItems,
            footerText: shareCardFooterText
        )
        .frame(width: 720)

        let renderer = ImageRenderer(content: cardView)
        renderer.scale = UIScreen.main.scale

        guard let uiImage = renderer.uiImage else {
            sharePhoto = nil
            return
        }

        sharePhoto = SubscriptionInsightsSharePhoto(
            image: Image(uiImage: uiImage),
            title: "固定費サマリー"
        )
    }

    private var shareAppIconImage: Image? {
        Image("PayLog")
    }
}

private struct PaymentSourceChartItem: Identifiable {
    let id: String
    let title: String
    let amount: Decimal
    let convertedCount: Int
    let totalCount: Int

    var doubleAmount: Double {
        NSDecimalNumber(decimal: amount).doubleValue
    }
}

private struct SubscriptionInsightsSharePhoto: Transferable {
    let image: Image
    let title: String

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.image)
    }
}

private struct SubscriptionInsightsShareCard: View {
    let appIcon: Image?
    let selectedPeriodTitle: String
    let totalAmountText: String
    let chartItems: [PaymentSourceChartItem]
    let footerText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("固定費サマリー")
                        .font(.title.bold())
                    Text("支払い元ごとの構成")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    if let appIcon {
                        appIcon
                            .resizable()
                            .frame(width: 24, height: 24)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(.white.opacity(0.45), lineWidth: 0.8)
                            }
                            .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
                    }

                    Text("PayLog")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: Capsule())
            }

            if chartItems.isEmpty {
                ContentUnavailableView(
                    "換算できる固定費がありません",
                    systemImage: "chart.pie",
                    description: Text("為替レートを設定すると支払い元ごとの構成を表示できます。")
                )
                .frame(maxWidth: .infinity, minHeight: 320)
            } else {
                Chart(chartItems) { item in
                    SectorMark(
                        angle: .value("金額", item.doubleAmount),
                        innerRadius: .ratio(0.62),
                        angularInset: 1.5
                    )
//                    .cornerRadius(4)
                    .foregroundStyle(by: .value("支払い元", item.title))
                }
                .chartLegend(position: .bottom, alignment: .center, spacing: 24)
                .frame(height: 320)
                .chartBackground { chartProxy in
                    GeometryReader { geometry in
                        if let plotFrame = chartProxy.plotFrame {
                            let frame = geometry[plotFrame]

                            VStack(spacing: 6) {
                                Text(selectedPeriodTitle)
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Text(totalAmountText)
                                    .font(.title.weight(.bold))
                                    .monospacedDigit()
                            }
                            .position(x: frame.midX, y: frame.midY)
                        }
                    }
                }
            }

            if let footerText {
                Text(footerText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 24, y: 10)
        )
        .padding(24)
        .background(Color(.systemGroupedBackground))
    }
}

private struct ExchangeRateEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let currency: SubscriptionCurrency
    let initialRate: Decimal?
    let formatter: NumberFormatter
    let onSave: (Decimal?) -> Void

    @State private var rateText: String
    @State private var validationMessage: String?

    init(
        currency: SubscriptionCurrency,
        initialRate: Decimal?,
        formatter: NumberFormatter,
        onSave: @escaping (Decimal?) -> Void
    ) {
        self.currency = currency
        self.initialRate = initialRate
        self.formatter = formatter
        self.onSave = onSave
        _rateText = State(initialValue: initialRate.flatMap {
            formatter.string(from: NSDecimalNumber(decimal: $0))
        } ?? "")
    }

    var body: some View {
        Form {
            Section {
                TextField("例: 155", text: $rateText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            } header: {
                Text("1 \(currency.code) = 何円")
            } footer: {
                if let validationMessage {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                }
            }

            if initialRate != nil {
                Section {
                    Button("レートを削除", role: .destructive) {
                        onSave(nil)
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle(currency.label)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: rateText) { _, newValue in
            saveIfPossible(using: newValue)
        }
    }

    private func saveIfPossible(using text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            validationMessage = nil
            return
        }

        let normalizedText = trimmedText.replacingOccurrences(of: ",", with: ".")
        let decimal = Decimal(string: normalizedText, locale: Locale(identifier: "en_US_POSIX"))
            ?? formatter.number(from: trimmedText).map { Decimal($0.doubleValue) }

        guard let decimal, decimal > 0 else {
            validationMessage = "0より大きい数値を入力してください。"
            return
        }

        validationMessage = nil
        onSave(decimal)
    }
}

#Preview {
    NavigationStack {
        SubscriptionInsightsView()
    }
    .modelContainer(PreviewData.makeModelContainer())
}
#Preview("Share Card", traits: .sizeThatFitsLayout) {
    SubscriptionInsightsShareCard(
        appIcon: Image("PayLog"),
        selectedPeriodTitle: "月額換算",
        totalAmountText: "¥18,400",
        chartItems: [
            PaymentSourceChartItem(
                id: "card-main",
                title: "三井住友カード",
                amount: 8400,
                convertedCount: 2,
                totalCount: 2
            ),
            PaymentSourceChartItem(
                id: "bank-main",
                title: "住信SBIネット銀行",
                amount: 5200,
                convertedCount: 1,
                totalCount: 1
            ),
            PaymentSourceChartItem(
                id: "invoice",
                title: "請求書払い",
                amount: 3100,
                convertedCount: 1,
                totalCount: 1
            ),
            PaymentSourceChartItem(
                id: "onsite",
                title: "現地払い",
                amount: 1700,
                convertedCount: 1,
                totalCount: 1
            )
        ],
        footerText: "アクティブな固定費 5 件中 4 件を換算しています。"
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
