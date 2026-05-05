//
//  SubscriptionInsightsView.swift
//  PayLog
//
//  Created by Codex on 2026/03/28.
//

import SwiftUI
import SwiftData

struct SubscriptionInsightsView: View {
    @Query private var subscriptions: [SubscriptionItem]
    @State private var yenRates = SubscriptionInsightSettings.loadYenRates()
    @State private var selectedPeriod: SubscriptionInsightPeriod = .month

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
                    Picker("表示単位", selection: $selectedPeriod) {
                        ForEach(SubscriptionInsightPeriod.allCases) { period in
                            Text(period.label).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("換算単位")
                }

                Section {
                    totalRow(
                        title: selectedPeriod.totalTitle,
                        amount: summary.total(for: selectedPeriod)
                    )
                } header: {
                    Text("合計")
                } footer: {
                    Text(totalFooterText)
                }

                Section {
                    ForEach(summary.paymentMethodGroups) { group in
                        paymentMethodDisclosureGroup(group)
                    }
                } header: {
                    Text("支払い元別")
                }

                Section {
                    if summary.rankedSubscriptions.isEmpty {
                        ContentUnavailableView(
                            "換算できる固定費がありません",
                            systemImage: "list.number",
                            description: Text("為替レートを設定するとランキングを表示できます。")
                        )
                    } else {
                        ForEach(Array(summary.rankedSubscriptions.enumerated()), id: \.element.id) { index, item in
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .frame(minWidth: 24, alignment: .leading)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.subscription.name)
                                    Text(item.subscription.amountWithBillingCycleText)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text(
                                    SubscriptionCurrency.jpy.formattedAmount(
                                        item.amount(for: selectedPeriod)
                                    )
                                )
                                    .fontWeight(.semibold)
                                    .monospacedDigit()
                            }
                        }
                    }
                } header: {
                    Text("ランキング")
                } footer: {
                    Text(selectedPeriod.rankingTitle)
                }
            }
        }
        .navigationTitle("固定費サマリー")
        .toolbar {
            if !activeSubscriptions.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(
                        item: Data(),
                        subject: Text("固定費サマリー"),
                        message: Text(shareSummaryText),
                        preview: SharePreview("固定費サマリー")
                    ) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("固定費サマリーを共有")
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

    private var totalFooterText: String {
        if summary.totalSubscriptionCount == 0 {
            return "アクティブな固定費を集計します。"
        }

        if summary.hasMissingRates {
            return "アクティブな固定費 \(summary.totalSubscriptionCount) 件中 \(summary.convertedSubscriptionCount) 件を換算しています。"
        }

        return "アクティブな固定費 \(summary.totalSubscriptionCount) 件をすべて換算しています。"
    }

    private var shareSummaryText: String {
        var lines: [String] = [
            "固定費サマリー",
            "合計: \(SubscriptionCurrency.jpy.formattedAmount(summary.total(for: selectedPeriod))) / \(selectedPeriod.shareUnitLabel)"
        ]

        let topSubscriptions = Array(summary.rankedSubscriptions.prefix(5))
        if !topSubscriptions.isEmpty {
            lines.append("")
            lines.append(topSubscriptions.count == 5 ? "上位5件" : "上位項目")
            lines.append(
                contentsOf: topSubscriptions.enumerated().map { index, item in
                    "\(index + 1). \(item.subscription.name): \(SubscriptionCurrency.jpy.formattedAmount(item.amount(for: selectedPeriod))) / \(selectedPeriod.shareUnitLabel)"
                }
            )
        }

        if summary.hasMissingRates {
            lines.append("")
            lines.append("メモ")
            lines.append(
                "・\(summary.totalSubscriptionCount - summary.convertedSubscriptionCount)件は為替レート未設定のため集計外"
            )
        }

        return lines.joined(separator: "\n")
    }

    @ViewBuilder
    private func totalRow(title: String, amount: Decimal) -> some View {
        LabeledContent(title) {
            Text(SubscriptionCurrency.jpy.formattedAmount(amount))
                .foregroundStyle(.primary)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private func paymentMethodDisclosureGroup(_ group: SubscriptionPaymentMethodGroup) -> some View {
        if group.subgroups.isEmpty {
            DisclosureGroup {
                ForEach(group.items) { item in
                    subscriptionItemRow(item)
                }
            } label: {
                groupRow(
                    title: group.paymentMethod.label,
                    amount: group.total(for: selectedPeriod),
                    convertedCount: group.convertedSubscriptionCount,
                    totalCount: group.totalSubscriptionCount
                )
            }
        } else {
            DisclosureGroup {
                ForEach(group.subgroups) { subgroup in
                    DisclosureGroup {
                        ForEach(subgroup.items) { item in
                            subscriptionItemRow(item)
                        }
                    } label: {
                        groupRow(
                            title: subgroup.title,
                            amount: subgroup.total(for: selectedPeriod),
                            convertedCount: subgroup.convertedSubscriptionCount,
                            totalCount: subgroup.totalSubscriptionCount
                        )
                    }
                }
            } label: {
                groupRow(
                    title: group.paymentMethod.label,
                    amount: group.total(for: selectedPeriod),
                    convertedCount: group.convertedSubscriptionCount,
                    totalCount: group.totalSubscriptionCount
                )
            }
        }
    }

    @ViewBuilder
    private func groupRow(
        title: String,
        amount: Decimal,
        convertedCount: Int,
        totalCount: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(title)
                    .foregroundStyle(.primary)

                Spacer()

                Text(SubscriptionCurrency.jpy.formattedAmount(amount))
                    .foregroundStyle(.primary)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }

            if convertedCount != totalCount {
                Text("\(convertedCount)/\(totalCount)件を換算")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func subscriptionItemRow(_ item: SubscriptionConvertedItem) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.subscription.name)
                Text(item.subscription.amountWithBillingCycleText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let amount = item.amount(for: selectedPeriod) {
                Text(SubscriptionCurrency.jpy.formattedAmount(amount))
                    .foregroundStyle(.primary)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            } else {
                Text("換算不可")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
