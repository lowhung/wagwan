import Foundation
import SwiftData

@Model
final class ContactLog {
    var id: UUID
    var contactedAt: Date
    var method: ContactMethod
    var notes: String?

    var friend: Friend?

    init(
        contactedAt: Date = Date(),
        method: ContactMethod = .other,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.contactedAt = contactedAt
        self.method = method
        self.notes = notes
    }
}

// MARK: - Contact Method

enum ContactMethod: String, Codable, CaseIterable, Identifiable {
    case call
    case text
    case inPerson
    case video
    case email
    case social
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .call: return "Call"
        case .text: return "Text"
        case .inPerson: return "Hangout"
        case .video: return "Video"
        case .email: return "Email"
        case .social: return "Social"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .call: return "phone.fill"
        case .text: return "message.fill"
        case .inPerson: return "person.2.fill"
        case .video: return "video.fill"
        case .email: return "envelope.fill"
        case .social: return "at"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var emoji: String {
        switch self {
        case .call: return "📞"
        case .text: return "💬"
        case .inPerson: return "🤗"
        case .video: return "📹"
        case .email: return "✉️"
        case .social: return "📱"
        case .other: return "✨"
        }
    }
}
