//
//  SwipeToDeleteTip.swift
//  PayLog
//
//  Created by Codex on 2026/03/29.
//

import SwiftUI
import TipKit

struct SwipeToDeleteTip: Tip {
    static let listReceivedFirstItem = Event(id: "listReceivedFirstItem")

    var title: Text {
        Text("左にスワイプで削除")
    }

    var message: Text? {
        Text("行を左にスワイプすると削除できます。")
    }

    var rules: [Rule] {
        #Rule(Self.listReceivedFirstItem) {
            $0.donations.count >= 1
        }
    }

    var options: [Option] {
        MaxDisplayCount(1)
    }
}

extension View {
    func swipeToDeleteTip(isPresented: Bool) -> some View {
        self.popoverTip(isPresented ? SwipeToDeleteTip() : nil, arrowEdge: .bottom)
    }
}
