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
        let now = Date()
        let mitsui = Bank(
            name: "三井住友銀行",
            branchName: "渋谷支店",
            accountNumber: "1234567",
            notes: "生活費",
            createdAt: now.addingTimeInterval(-60 * 60 * 24 * 6)
        )
        let mufg = Bank(
            name: "三菱UFJ銀行",
            branchName: "新宿支店",
            accountNumber: "7654321",
            isActive: false,
            createdAt: now.addingTimeInterval(-60 * 60 * 24 * 5)
        )

        let visa = Card(
            name: "Olive",
            lastFourDigits: "1234",
            withdrawalDay: 26,
            notes: "メインカード",
            bank: mitsui,
            createdAt: now.addingTimeInterval(-60 * 60 * 24 * 4)
        )
        let master = Card(
            name: "MUFG Card",
            lastFourDigits: "9876",
            withdrawalDay: 10,
            bank: mufg,
            isActive: false,
            createdAt: now.addingTimeInterval(-60 * 60 * 24 * 3)
        )

        let suica = ElectronicMoney(
            name: "Suica",
            notes: "通勤用",
            card: visa,
            createdAt: now.addingTimeInterval(-60 * 60 * 24 * 2)
        )
        let payPay = ElectronicMoney(
            name: "PayPay",
            card: master,
            isActive: false,
            createdAt: now.addingTimeInterval(-60 * 60 * 24)
        )

        let netflix = SubscriptionItem(
            name: "Netflix",
            amount: 1490,
            billingDay: 18,
            billingCycle: .monthly,
            notes: "家族共有",
            card: visa,
            createdAt: now.addingTimeInterval(-60 * 60 * 18)
        )
        let spotify = SubscriptionItem(
            name: "Spotify",
            amount: 9800,
            billingDay: 29,
            billingMonth: 2,
            billingCycle: .yearly,
            card: master,
            isActive: false,
            createdAt: now.addingTimeInterval(-60 * 60 * 12)
        )
        let youtubePremium = SubscriptionItem(
            name: "YouTube Premium",
            amount: 1280,
            billingDay: 31,
            billingCycle: .monthly,
            card: master,
            isActive: false,
            createdAt: now.addingTimeInterval(-60 * 60 * 6)
        )
        let gymMembership = SubscriptionItem(
            name: "ジム会費",
            amount: 7980,
            billingDay: 27,
            billingCycle: .monthly,
            paymentMethod: .bankAccount,
            bank: mitsui,
            createdAt: now.addingTimeInterval(-60 * 60 * 3)
        )
        let adobeCreativeCloud = SubscriptionItem(
            name: "Adobe Creative Cloud",
            amount: 72800,
            billingDay: 30,
            billingMonth: 11,
            billingCycle: .yearly,
            card: visa,
            createdAt: now
        )

        context.insert(mitsui)
        context.insert(mufg)
        context.insert(visa)
        context.insert(master)
        context.insert(suica)
        context.insert(payPay)
        context.insert(netflix)
        context.insert(spotify)
        context.insert(youtubePremium)
        context.insert(gymMembership)
        context.insert(adobeCreativeCloud)
    }
}
