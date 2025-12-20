import SwiftUI

struct StatusBadge: View {
    let status: ContactStatus

    private var color: Color {
        switch status {
        case .overdue: return .statusOverdue
        case .dueSoon: return .statusDueSoon
        case .onTrack: return .statusOnTrack
        }
    }

    private var icon: String {
        switch status {
        case .overdue: return "exclamationmark.circle.fill"
        case .dueSoon: return "clock.fill"
        case .onTrack: return "checkmark.circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.labelSmall)
            Text(status.label)
                .font(.labelMedium)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs + 2)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

// MARK: - Compact Badge (just the dot)

struct StatusDot: View {
    let status: ContactStatus

    private var color: Color {
        switch status {
        case .overdue: return .statusOverdue
        case .dueSoon: return .statusDueSoon
        case .onTrack: return .statusOnTrack
        }
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        StatusBadge(status: .overdue)
        StatusBadge(status: .dueSoon)
        StatusBadge(status: .onTrack)

        HStack(spacing: Spacing.md) {
            StatusDot(status: .overdue)
            StatusDot(status: .dueSoon)
            StatusDot(status: .onTrack)
        }
    }
    .padding()
}
