import EventKit
import SwiftUI

@MainActor
final class CalendarService {
    static let shared = CalendarService()

    private let eventStore = EKEventStore()

    private init() {}

    // MARK: - Authorization

    func requestAccess() async -> Bool {
        do {
            return try await eventStore.requestFullAccessToEvents()
        } catch {
            print("Calendar access error: \(error)")
            return false
        }
    }

    var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    // MARK: - Create Reminder Event

    func createReminder(for friend: Friend) async {
        guard await requestAccess() else {
            return
        }

        // Calculate the reminder date
        let reminderDate: Date
        if let lastContact = friend.lastContactedAt {
            reminderDate = Calendar.current.date(
                byAdding: .day,
                value: friend.reminderIntervalDays,
                to: lastContact
            ) ?? Date()
        } else {
            reminderDate = Calendar.current.date(
                byAdding: .day,
                value: friend.reminderIntervalDays,
                to: Date()
            ) ?? Date()
        }

        // Don't create events in the past
        let eventDate = max(reminderDate, Date())

        // Remove existing event if any
        if let existingIdentifier = friend.calendarEventIdentifier {
            removeEvent(identifier: existingIdentifier)
        }

        // Create the event
        let event = EKEvent(eventStore: eventStore)
        event.title = "Reconnect with \(friend.name)"
        event.notes = createEventNotes(for: friend)
        event.startDate = eventDate
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: eventDate)
        event.calendar = eventStore.defaultCalendarForNewEvents
        event.isAllDay = true

        // Add an alert
        let alarm = EKAlarm(relativeOffset: -3600) // 1 hour before
        event.addAlarm(alarm)

        // Add URL to open the app
        if let appUrl = URL(string: "reconnect://friend/\(friend.id.uuidString)") {
            event.url = appUrl
        }

        do {
            try eventStore.save(event, span: .thisEvent)
            friend.calendarEventIdentifier = event.eventIdentifier
        } catch {
            print("Failed to save event: \(error)")
        }
    }

    private func createEventNotes(for friend: Friend) -> String {
        var notes = "Time to reach out to \(friend.name)!"

        if let phone = friend.phoneNumber {
            notes += "\n\nPhone: \(phone)"
        }

        if let email = friend.email {
            notes += "\nEmail: \(email)"
        }

        if let friendNotes = friend.notes {
            notes += "\n\nNotes: \(friendNotes)"
        }

        return notes
    }

    // MARK: - Remove Event

    private func removeEvent(identifier: String) {
        guard let event = eventStore.event(withIdentifier: identifier) else {
            return
        }

        do {
            try eventStore.remove(event, span: .thisEvent)
        } catch {
            print("Failed to remove event: \(error)")
        }
    }

    // MARK: - Update Reminder

    func updateReminder(for friend: Friend) async {
        // Simply recreate the reminder with new dates
        await createReminder(for: friend)
    }
}
