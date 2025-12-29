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

    // Streak tracking
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastStreakDate: Date?

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

    // MARK: - Streak Management

    /// Updates streak when logging a new contact. Returns true if a milestone was reached.
    @discardableResult
    func updateStreak(contactDate: Date = Date()) -> StreakMilestone? {
        let calendar = Calendar.current

        // Check if this contact was on-time (before or on the due date)
        let wasOnTime: Bool
        if let nextDate = nextContactDate {
            wasOnTime = contactDate <= calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
        } else {
            // First contact is always on-time
            wasOnTime = true
        }

        // Check if we're continuing a streak or starting fresh
        let isNewStreakDay: Bool
        if let lastStreak = lastStreakDate {
            // Different day from last streak update
            isNewStreakDay = !calendar.isDate(contactDate, inSameDayAs: lastStreak)
        } else {
            isNewStreakDay = true
        }

        guard isNewStreakDay else { return nil }

        if wasOnTime {
            currentStreak += 1
            lastStreakDate = contactDate

            if currentStreak > longestStreak {
                longestStreak = currentStreak
            }

            // Check for milestones
            return StreakMilestone.forStreak(currentStreak)
        } else {
            // Streak broken - reset
            currentStreak = 1
            lastStreakDate = contactDate
            return nil
        }
    }

    /// Whether the streak is currently active (not broken)
    var isStreakActive: Bool {
        guard currentStreak > 0, let lastStreak = lastStreakDate else {
            return false
        }

        // Streak is active if last contact was within the reminder interval + grace period
        let gracePeriodDays = reminderIntervalDays + 3
        guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -gracePeriodDays, to: Date()) else {
            return false
        }

        return lastStreak >= cutoffDate
    }
}

// MARK: - Streak Milestones

enum StreakMilestone: Int, CaseIterable {
    case first = 1
    case weekly = 7
    case monthly = 30
    case century = 100

    var message: String {
        switch self {
        case .first: return "First check-in!"
        case .weekly: return "1 week streak!"
        case .monthly: return "30 day streak!"
        case .century: return "100 day streak!"
        }
    }

    var emoji: String {
        switch self {
        case .first: return "🎉"
        case .weekly: return "🔥"
        case .monthly: return "⭐"
        case .century: return "🏆"
        }
    }

    static func forStreak(_ count: Int) -> StreakMilestone? {
        // Return milestone if we just hit it exactly
        return StreakMilestone(rawValue: count)
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

    var description: String {
        switch self {
        case .weekly:
            return "Perfect for close friends you talk to often"
        case .biweekly:
            return "Great for staying close without overwhelming"
        case .monthly:
            return "Ideal for friends you catch up with regularly"
        case .quarterly:
            return "Good for keeping in touch with distant friends"
        }
    }
}
