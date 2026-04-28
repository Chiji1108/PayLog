//
//  SampleDataSeeder.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import Foundation
import SwiftData

enum SampleDataSeeder {
    static func seed(in context: ModelContext) {
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()

        func anchoredDate(year: Int, month: Int, day: Int) -> Date {
            let components = DateComponents(year: year, month: month, day: day)
            return calendar.date(from: components) ?? now
        }

        func createdAt(minutesAgo: Int) -> Date {
            calendar.date(byAdding: .minute, value: -minutesAgo, to: now) ?? now
        }

        let currentYear = calendar.component(.year, from: now)
        let mitsui = Bank(
            name: "三井住友銀行",
            branchName: "渋谷支店",
            accountNumber: "1234567",
            notes: "生活費",
            createdAt: createdAt(minutesAgo: 120)
        )
        let mufg = Bank(
            name: "三菱UFJ銀行",
            branchName: "新宿支店",
            accountNumber: "7654321",
            notes: "息子の貯金用口座",
            isActive: false,
            createdAt: createdAt(minutesAgo: 180)
        )

        let visa = Card(
            name: "Olive",
            lastFourDigits: "1234",
            closingDay: 15,
            withdrawalDay: 26,
            notes: "メインカード",
            bank: mitsui,
            createdAt: createdAt(minutesAgo: 100)
        )
        let master = Card(
            name: "MUFG Card",
            lastFourDigits: "9876",
            closingDay: 31,
            withdrawalDay: 10,
            bank: mufg,
            isActive: false,
            createdAt: createdAt(minutesAgo: 160)
        )
        let rakuten = Card(
            name: "楽天カード",
            lastFourDigits: "4455",
            withdrawalDay: 27,
            notes: "あとで口座設定する",
            annualFeeSetting: .free,
            createdAt: createdAt(minutesAgo: 110)
        )

        let suica = ElectronicMoney(
            name: "Suica",
            notes: "通勤用",
            card: visa,
            createdAt: createdAt(minutesAgo: 80)
        )
        let payPay = ElectronicMoney(
            name: "PayPay",
            notes: "幹事用",
            card: master,
            isActive: true,
            createdAt: createdAt(minutesAgo: 140)
        )

        let netflix = SubscriptionItem(
            name: "Netflix",
            amount: 1490,
            createdAt: createdAt(minutesAgo: 10),
            billingUnit: .month,
            billingAnchorDate: anchoredDate(year: currentYear, month: 3, day: 18),
            paymentMethod: .card,
            notes: "家族共有",
            card: visa
        )
        let spotify = SubscriptionItem(
            name: "Spotify",
            amount: 980,
            createdAt: createdAt(minutesAgo: 220),
            billingUnit: .month,
            billingAnchorDate: anchoredDate(year: currentYear, month: 4, day: 5),
            paymentMethod: .card,
            card: master,
            isActive: false
        )
        let youtubePremium = SubscriptionItem(
            name: "YouTube Premium",
            amount: 1280,
            createdAt: createdAt(minutesAgo: 260),
            billingUnit: .month,
            billingAnchorDate: anchoredDate(year: currentYear, month: 4, day: 12),
            paymentMethod: .card,
            card: master,
            isActive: false
        )
        let petTrimming = SubscriptionItem(
            name: "ペットのトリミング",
            amount: 7980,
            createdAt: createdAt(minutesAgo: 30),
            billingInterval: 6,
            billingUnit: .week,
            billingAnchorDate: anchoredDate(year: currentYear, month: 4, day: 1),
            paymentMethod: .onSite
        )
        let fixedAssetTax = SubscriptionItem(
            name: "固定資産税",
            amount: 44000,
            createdAt: createdAt(minutesAgo: 40),
            billingInterval: 3,
            billingUnit: .month,
            billingAnchorDate: anchoredDate(year: currentYear, month: 4, day: 30),
            paymentMethod: .invoice
        )
        let chatGPTPlus = SubscriptionItem(
            name: "ChatGPT Plus",
            amount: 20.00,
            createdAt: createdAt(minutesAgo: 15),
            billingUnit: .month,
            currency: .usd,
            billingAnchorDate: anchoredDate(year: currentYear, month: 11, day: 30),
            paymentMethod: .card,
            card: visa
        )
        let oliveAnnualFee = SubscriptionItem(
            name: "Olive 年会費",
            amount: 5500,
            createdAt: createdAt(minutesAgo: 20),
            billingUnit: .year,
            billingAnchorDate: anchoredDate(year: currentYear, month: 5, day: 1),
            paymentMethod: .card,
            card: visa
        )
        let mufgAnnualFee = SubscriptionItem(
            name: "MUFG Card 年会費",
            amount: 1375,
            createdAt: createdAt(minutesAgo: 170),
            billingUnit: .year,
            billingAnchorDate: anchoredDate(year: currentYear, month: 9, day: 15),
            paymentMethod: .bankAccount,
            bank: mufg,
            isActive: false
        )

        visa.annualFeeSubscription = oliveAnnualFee
        master.annualFeeSubscription = mufgAnnualFee

        context.insert(mitsui)
        context.insert(mufg)
        context.insert(visa)
        context.insert(master)
        context.insert(rakuten)
        context.insert(suica)
        context.insert(payPay)
        context.insert(netflix)
        context.insert(spotify)
        context.insert(youtubePremium)
        context.insert(petTrimming)
        context.insert(fixedAssetTax)
        context.insert(chatGPTPlus)
        context.insert(oliveAnnualFee)
        context.insert(mufgAnnualFee)
    }
}
