import SwiftUI

struct FriendCard: View {
    let friend: Friend
    var onTap: () -> Void = {}

    @State private var isPressed = false

    var body: some View {
        Button(action: {
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
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.snappy) {
                isPressed = pressing
            }
        }, perform: {})
    }

    // MARK: - Subviews

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(friend.avatarColor.opacity(0.2))

            if let photoData = friend.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
            } else {
                Text(friend.initials)
                    .font(.headlineMedium)
                    .foregroundStyle(friend.avatarColor)
            }
        }
        .frame(width: 50, height: 50)
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
        FriendCard(friend: {
            let f = Friend(name: "Sarah Chen", phoneNumber: "555-1234", reminderIntervalDays: 14)
            f.lastContactedAt = Calendar.current.date(byAdding: .day, value: -20, to: Date())
            return f
        }())

        FriendCard(friend: {
            let f = Friend(name: "Marcus Johnson", reminderIntervalDays: 7)
            f.lastContactedAt = Calendar.current.date(byAdding: .day, value: -5, to: Date())
            return f
        }())

        FriendCard(friend: {
            let f = Friend(name: "Emma Wilson", reminderIntervalDays: 30)
            f.lastContactedAt = Date()
            return f
        }())
    }
    .padding()
    .background(Color.warmGray)
}
