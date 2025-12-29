import SwiftUI

struct FriendCard: View {
    let friend: Friend
    var onTap: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var label = friend.name

        // Status
        label += ", \(friend.status.label)"

        // Last contact info
        if let days = friend.daysSinceLastContact {
            switch days {
            case 0:
                label += ", contacted today"
            case 1:
                label += ", contacted yesterday"
            default:
                label += ", contacted \(days) days ago"
            }
        } else {
            label += ", never contacted"
        }

        // Due info
        let daysUntilDue = friend.daysUntilDue
        if daysUntilDue < 0 {
            label += ", \(abs(daysUntilDue)) days overdue"
        } else if daysUntilDue <= 3 {
            label += ", due in \(daysUntilDue) days"
        }

        return label
    }

    var body: some View {
        Button(action: {
            HapticService.shared.cardTap()
            onTap()
        }) {
            HStack(spacing: Spacing.md) {
                // Avatar
                avatarView

                // Info
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(friend.name)
                        .font(.headlineMedium)
                        .foregroundStyle(Color.warmBlack)

                    lastContactText
                }

                Spacer()

                // Status
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    StatusBadge(status: friend.status)

                    if friend.status != .onTrack {
                        dueText
                    }
                }
            }
            .padding(Spacing.md)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
            .cardShadow()
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to view details")
        .accessibilityAddTraits(.isButton)
        .onLongPressGesture(
            minimumDuration: .infinity,
            pressing: { pressing in
                withAnimation(reduceMotion ? .none : .snappy) {
                    isPressed = pressing
                }
            }, perform: {})
    }

    // MARK: - Subviews

    private var avatarView: some View {
        ZStack {
            // Soft glow effect behind avatar
            Circle()
                .fill(RadialGradient.avatarGlow(color: friend.avatarColor))
                .frame(width: 60, height: 60)

            Circle()
                .fill(friend.avatarColor.opacity(0.2))
                .frame(width: 50, height: 50)

            if let photoData = friend.photoData,
                let uiImage = UIImage(data: photoData)
            {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Text(friend.initials)
                    .font(.headlineMedium)
                    .foregroundStyle(friend.avatarColor)
            }
        }
        .frame(width: 60, height: 60)
    }

    private var lastContactText: some View {
        Group {
            if let days = friend.daysSinceLastContact {
                Text(daysAgoText(days))
                    .font(.bodySmall)
                    .foregroundStyle(Color.warmGrayDark)
            } else {
                Text("Never contacted")
                    .font(.bodySmall)
                    .foregroundStyle(Color.warmGrayDark)
            }
        }
    }

    private var dueText: some View {
        Group {
            let days = friend.daysUntilDue
            if days < 0 {
                Text("\(abs(days))d overdue")
                    .font(.labelSmall)
                    .foregroundStyle(Color.coral)
            } else {
                Text("Due in \(days)d")
                    .font(.labelSmall)
                    .foregroundStyle(Color.sunflowerDark)
            }
        }
    }

    private func daysAgoText(_ days: Int) -> String {
        switch days {
        case 0: return "Today"
        case 1: return "Yesterday"
        default: return "\(days) days ago"
        }
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        FriendCard(
            friend: {
                let f = Friend(
                    name: "Sarah Chen", phoneNumber: "555-1234", reminderIntervalDays: 14)
                f.lastContactedAt = Calendar.current.date(byAdding: .day, value: -20, to: Date())
                return f
            }())

        FriendCard(
            friend: {
                let f = Friend(name: "Marcus Johnson", reminderIntervalDays: 7)
                f.lastContactedAt = Calendar.current.date(byAdding: .day, value: -5, to: Date())
                return f
            }())

        FriendCard(
            friend: {
                let f = Friend(name: "Emma Wilson", reminderIntervalDays: 30)
                f.lastContactedAt = Date()
                return f
            }())
    }
    .padding()
    .background(Color.warmGray)
}
