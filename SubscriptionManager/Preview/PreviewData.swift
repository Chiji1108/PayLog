//
//  PreviewData.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI
import SwiftData

enum PreviewData {
    static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            Bank.self,
            Card.self,
            ElectronicMoney.self,
            SubscriptionItem.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            seedSampleData(in: container.mainContext)
            return container
        } catch {
            fatalError("Could not create preview container: \(error)")
        }
    }

    private static func seedSampleData(in context: ModelContext) {
        let mitsui = Bank(name: "三井住友銀行")
        let mufg = Bank(name: "三菱UFJ銀行", isActive: false)

        let visa = Card(name: "Olive", bank: mitsui)
        let master = Card(name: "MUFG Card", bank: mufg, isActive: false)

        let suica = ElectronicMoney(name: "Suica", card: visa)
        let payPay = ElectronicMoney(name: "PayPay", card: master, isActive: false)

        let netflix = SubscriptionItem(name: "Netflix", monthlyAmount: 1490, card: visa)
        let spotify = SubscriptionItem(name: "Spotify", monthlyAmount: 980, card: master, isActive: false)

        context.insert(mitsui)
        context.insert(mufg)
        context.insert(visa)
        context.insert(master)
        context.insert(suica)
        context.insert(payPay)
        context.insert(netflix)
        context.insert(spotify)
    }
}
struct PreviewSampleData: PreviewModifier {
    static func makeSharedContext() throws -> ModelContainer {
        PreviewData.makeModelContainer()
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    @MainActor
    static var sampleData: Self {
        .modifier(PreviewSampleData())
    }
}
