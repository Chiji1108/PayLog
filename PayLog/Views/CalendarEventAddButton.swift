//
//  CalendarEventAddButton.swift
//  PayLog
//
//  Created by Codex on 2026/03/29.
//

import SwiftUI
import EventKit
import EventKitUI
import UIKit

struct CalendarEventDraft: Identifiable {
    let id = UUID()
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let notes: String?
    let recurrence: CalendarEventRecurrence?
}

enum CalendarEventRecurrence {
    case weekly(interval: Int)
    case monthly(interval: Int, dayOfMonth: Int)
    case yearly(interval: Int, month: Int, dayOfMonth: Int)

    func makeRule() -> EKRecurrenceRule? {
        switch self {
        case let .weekly(interval):
            EKRecurrenceRule(recurrenceWith: .weekly, interval: max(interval, 1), end: nil)
        case let .monthly(interval, dayOfMonth):
            EKRecurrenceRule(
                recurrenceWith: .monthly,
                interval: max(interval, 1),
                daysOfTheWeek: nil,
                daysOfTheMonth: [NSNumber(value: dayOfMonth)],
                monthsOfTheYear: nil,
                weeksOfTheYear: nil,
                daysOfTheYear: nil,
                setPositions: nil,
                end: nil
            )
        case let .yearly(interval, month, dayOfMonth):
            EKRecurrenceRule(
                recurrenceWith: .yearly,
                interval: max(interval, 1),
                daysOfTheWeek: nil,
                daysOfTheMonth: [NSNumber(value: dayOfMonth)],
                monthsOfTheYear: [NSNumber(value: month)],
                weeksOfTheYear: nil,
                daysOfTheYear: nil,
                setPositions: nil,
                end: nil
            )
        }
    }
}

struct CalendarEventAddButton<Label: View>: View {
    let title: String
    let draft: CalendarEventDraft
    @ViewBuilder let label: () -> Label

    @State private var selectedDraft: CalendarEventDraft?

    var body: some View {
        Button {
            selectedDraft = draft
        } label: {
            label()
        }
        .sheet(item: $selectedDraft) { draft in
            CalendarEventEditorSheet(draft: draft)
        }
    }
}

struct CalendarEventEditorSheet: UIViewControllerRepresentable {
    let draft: CalendarEventDraft

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let controller = EKEventEditViewController()
        controller.eventStore = context.coordinator.eventStore
        controller.event = context.coordinator.makeEvent(from: draft)
        controller.editViewDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {
        uiViewController.eventStore = context.coordinator.eventStore
        uiViewController.event = context.coordinator.makeEvent(from: draft)
    }

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        let eventStore = EKEventStore()

        func makeEvent(from draft: CalendarEventDraft) -> EKEvent {
            let event = EKEvent(eventStore: eventStore)
            event.title = draft.title
            event.startDate = draft.startDate
            event.endDate = draft.endDate
            event.isAllDay = draft.isAllDay
            event.notes = draft.notes

            if let recurrenceRule = draft.recurrence?.makeRule() {
                event.addRecurrenceRule(recurrenceRule)
            }

            return event
        }

        func eventEditViewController(
            _ controller: EKEventEditViewController,
            didCompleteWith action: EKEventEditViewAction
        ) {
            controller.dismiss(animated: true)
        }
    }
}
