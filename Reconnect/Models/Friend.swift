import Foundation
import SwiftData

@Model
final class Friend {
    var id: UUID
    var name: String
    var phoneNumber: String?
    var email: String?
    var notes: String?
    var photoData: Data?

    // Reminder settings
    var reminderIntervalDays: Int
    var lastContactedAt: Date?
    var createdAt: Date

    // Calendar event tracking
    var calendarEventIdentifier: String?

    @Relationship(deleteRule: .cascade, inverse: \ContactLog.friend)
    var contactLogs: [ContactLog] = []

    init(
        name: String,
        phoneNumber: String? = nil,
        email: String? = nil,
        notes: String? = nil,
        reminderIntervalDays: Int = 14
    ) {
        self.id = UUID()
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.notes = notes
        self.reminderIntervalDays = reminderIntervalDays
        self.createdAt = Date()
    }

    // MARK: - Computed Properties

    var nextContactDate: Date? {
        guard let lastContact = lastContactedAt else {
            return createdAt
        }
        return Calendar.current.date(byAdding: .day, value: reminderIntervalDays, to: lastContact)
    }

    var status: ContactStatus {
        guard let nextDate = nextContactDate else {
            return .overdue
        }

        let now = Date()
        let daysUntilDue = Calendar.current.dateComponents([.day], from: now, to: nextDate).day ?? 0

        if daysUntilDue < 0 {
            return .overdue
        } else if daysUntilDue <= 3 {
            return .dueSoon
        } else {
            return .onTrack
        }
    }

    var daysUntilDue: Int {
        guard let nextDate = nextContactDate else {
            return -999
        }
        return Calendar.current.dateComponents([.day], from: Date(), to: nextDate).day ?? 0
    }

    var daysSinceLastContact: Int? {
        guard let lastContact = lastContactedAt else {
            return nil
        }
        return Calendar.current.dateComponents([.day], from: lastContact, to: Date()).day
    }

    var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Contact Status

enum ContactStatus: String, Codable {
    case overdue
    case dueSoon
    case onTrack

    var label: String {
        switch self {
        case .overdue: return "Overdue"
        case .dueSoon: return "Due Soon"
        case .onTrack: return "On Track"
        }
    }

    var sortOrder: Int {
        switch self {
        case .overdue: return 0
        case .dueSoon: return 1
        case .onTrack: return 2
        }
    }
}

// MARK: - Reminder Interval Presets

enum ReminderInterval: Int, CaseIterable, Identifiable {
    case weekly = 7
    case biweekly = 14
    case monthly = 30
    case quarterly = 90

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .weekly: return "Weekly"
        case .biweekly: return "Every 2 weeks"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        }
    }
}
