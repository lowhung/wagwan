import Foundation

extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var isThisMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }

    func daysFrom(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }

    func daysUntil(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: self, to: date).day ?? 0
    }

    var relativeDescription: String {
        if isToday {
            return "Today"
        } else if isYesterday {
            return "Yesterday"
        } else if isThisWeek {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: self)
        } else if isThisMonth {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: self)
        } else {
            return formatted(date: .abbreviated, time: .omitted)
        }
    }

    var shortRelativeDescription: String {
        let days = Date().daysFrom(self)

        switch days {
        case 0:
            return "Today"
        case 1:
            return "Yesterday"
        case 2...6:
            return "\(days) days ago"
        case 7...13:
            return "1 week ago"
        case 14...20:
            return "2 weeks ago"
        case 21...29:
            return "3 weeks ago"
        case 30...59:
            return "1 month ago"
        case 60...89:
            return "2 months ago"
        default:
            let months = days / 30
            return "\(months) months ago"
        }
    }
}
