//
//  EditModeDisabledToolbarContent.swift
//  PayLog
//
//  Created by OpenAI Codex.
//

import SwiftUI

struct EditModeDisabledToolbarContent<Content: View>: View {
    @Environment(\.editMode) private var editMode

    @ViewBuilder private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .disabled(isEditing)
    }

    private var isEditing: Bool {
        editMode?.wrappedValue.isEditing == true
    }
}
