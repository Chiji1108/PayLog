//
//  ContentView.swift
//  SubscriptionManager
//
//  Created by 千々岩真吾 on 2026/03/28.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            SubscriptionTabView()
                .tabItem {
                    Label("サブスク", systemImage: "repeat.circle")
                }

            CardTabView()
                .tabItem {
                    Label("カード", systemImage: "creditcard")
                }

            ElectronicMoneyTabView()
                .tabItem {
                    Label("電子マネー", systemImage: "iphone.gen3")
                }

            BankTabView()
                .tabItem {
                    Label("銀行", systemImage: "building.columns")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewData.makeModelContainer())
}
