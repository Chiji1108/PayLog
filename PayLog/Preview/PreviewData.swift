//
//  PreviewData.swift
//  PayLog
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
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            SampleDataSeeder.seedPreviewData(in: container.mainContext)
            return container
        } catch {
            fatalError("Could not create preview container: \(error)")
        }
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
