import SwiftUI

struct FriendCard: View {
    let friend: Friend
    var onTap: () -> Void = {}
    var onLogContact: () -> Void = {}
    var onCall: (() -> Void)?
    var onMessage: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false
    @State private var offset: CGFloat = 0
    @State private var isShowingLeadingActions = false
    @State private var isShowingTrailingActions = false
    @State private var avatarPulse = false

    private let actionThreshold: CGFloat = 60
    private let fullSwipeThreshold: CGFloat = 120
    private let leadingActionWidth: CGFloat = 80
    private let trailingActionWidth: CGFloat = 160

    // Status accent color for left border
    private var statusAccentColor: Color {
        switch friend.status {
        case .onTrack:
            return Color.sage
        case .dueSoon:
            return Color.sunflower
        case .overdue:
            return Color.coral.opacity(0.7)
        }
    }

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

    private var hasContactOptions: Bool {
        onCall != nil || onMessage != nil
    }

    var body: some View {
        ZStack {
            // Background actions
            HStack(spacing: 0) {
                // Leading action (Log Contact) - revealed on swipe right
                leadingActions
                    .frame(width: leadingActionWidth)
                    .opacity(offset > 0 ? 1 : 0)

                Spacer()

                // Trailing actions (Call/Message) - revealed on swipe left
                if hasContactOptions {
                    trailingActions
                        .frame(width: trailingActionWidth)
                        .opacity(offset < 0 ? 1 : 0)
                }
            }

            // Main card content
            cardContent
                .offset(x: offset)
                .gesture(swipeGesture)
        }
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to view details. Swipe for quick actions.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Log Contact") {
            performLogContact()
        }
        .accessibilityAction(named: "Call", onCall ?? {})
        .accessibilityAction(named: "Message", onMessage ?? {})
    }

    // MARK: - Card Content

    private var cardContent: some View {
        Button(action: {
            if offset != 0 {
                resetOffset()
            } else {
                HapticService.shared.cardTap()
                onTap()
            }
        }) {
            HStack(spacing: 0) {
                // Status accent border
                RoundedRectangle(cornerRadius: 3)
                    .fill(statusAccentColor)
                    .frame(width: 4)
                    .padding(.vertical, Spacing.sm)

                HStack(spacing: Spacing.md) {
                    // Avatar
                    avatarView

                    // Info
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(friend.name)
                            .font(.headlineMedium)
                            .foregroundStyle(Color.textPrimary)

                        lastContactText
                    }

                    Spacer()

                    // Status
                    VStack(alignment: .trailing, spacing: Spacing.xs) {
                        StatusBadge(status: friend.status)

                        friendlyDueText
                    }
                }
                .padding(Spacing.md)
            }
            .background(
                ZStack {
                    Color.cardBackground
                    // Subtle warm gradient overlay
                    LinearGradient(
                        colors: [
                            statusAccentColor.opacity(0.03),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
            .shadow(
                color: statusAccentColor.opacity(0.15),
                radius: 8,
                x: 0,
                y: 4
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(
            minimumDuration: .infinity,
            pressing: { pressing in
                withAnimation(reduceMotion ? .none : .snappy) {
                    isPressed = pressing
                }
            }, perform: {})
    }

    // MARK: - Swipe Actions

    private var leadingActions: some View {
        Button(action: performLogContact) {
            VStack(spacing: Spacing.xxs) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                Text("Log")
                    .font(.labelSmall)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.sage)
        }
    }

    private var trailingActions: some View {
        HStack(spacing: 0) {
            if let onCall = onCall {
                Button(action: {
                    HapticService.shared.buttonTap()
                    resetOffset()
                    onCall()
                }) {
                    VStack(spacing: Spacing.xxs) {
                        Image(systemName: "phone.fill")
                            .font(.title2)
                        Text("Call")
                            .font(.labelSmall)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.sage)
                }
            }

            if let onMessage = onMessage {
                Button(action: {
                    HapticService.shared.buttonTap()
                    resetOffset()
                    onMessage()
                }) {
                    VStack(spacing: Spacing.xxs) {
                        Image(systemName: "message.fill")
                            .font(.title2)
                        Text("Text")
                            .font(.labelSmall)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.lavender)
                }
            }
        }
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                let translation = value.translation.width

                // Limit swipe distance
                if translation > 0 {
                    // Swiping right - show log action
                    offset = min(translation, leadingActionWidth + 20)
                } else if hasContactOptions {
                    // Swiping left - show contact actions
                    offset = max(translation, -(trailingActionWidth + 20))
                }

                // Haptic feedback at threshold
                if abs(translation) > actionThreshold && !isShowingLeadingActions && !isShowingTrailingActions {
                    HapticService.shared.selection()
                    if translation > 0 {
                        isShowingLeadingActions = true
                    } else {
                        isShowingTrailingActions = true
                    }
                }
            }
            .onEnded { value in
                let translation = value.translation.width

                withAnimation(reduceMotion ? .none : .snappy) {
                    // Full swipe right - trigger log contact
                    if translation > fullSwipeThreshold {
                        performLogContact()
                    }
                    // Partial swipe right - snap to show action
                    else if translation > actionThreshold {
                        offset = leadingActionWidth
                    }
                    // Full swipe left - snap to show actions
                    else if translation < -actionThreshold && hasContactOptions {
                        offset = -trailingActionWidth
                    }
                    // Reset
                    else {
                        offset = 0
                    }

                    isShowingLeadingActions = false
                    isShowingTrailingActions = false
                }
            }
    }

    // MARK: - Actions

    private func performLogContact() {
        HapticService.shared.success()
        resetOffset()
        onLogContact()
    }

    private func resetOffset() {
        withAnimation(reduceMotion ? .none : .snappy) {
            offset = 0
        }
    }

    // MARK: - Subviews

    private var avatarView: some View {
        ZStack {
            // Gentle pulse for overdue friends
            if friend.status == .overdue && !reduceMotion {
                Circle()
                    .fill(Color.coral.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .scaleEffect(avatarPulse ? 1.2 : 1.0)
                    .opacity(avatarPulse ? 0 : 0.6)
                    .onAppear {
                        withAnimation(
                            .easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: false)
                        ) {
                            avatarPulse = true
                        }
                    }
            }

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
                    .foregroundStyle(Color.textSecondary)
            } else {
                Text("Never contacted")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }

    private var friendlyDueText: some View {
        Group {
            let days = friend.daysUntilDue
            if days < 0 {
                Text("Miss them? Say hi!")
                    .font(.labelSmall)
                    .foregroundStyle(Color.coral)
            } else if days == 0 {
                Text("Say hi today!")
                    .font(.labelSmall)
                    .foregroundStyle(Color.sunflowerDark)
            } else if days == 1 {
                Text("Say hi tomorrow")
                    .font(.labelSmall)
                    .foregroundStyle(Color.textSecondary)
            } else if days <= 7 {
                Text("Say hi by \(dueDayName)")
                    .font(.labelSmall)
                    .foregroundStyle(Color.textSecondary)
            } else {
                Text("Next: \(days) days")
                    .font(.labelSmall)
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }

    private var dueDayName: String {
        let dueDate = Calendar.current.date(byAdding: .day, value: friend.daysUntilDue, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: dueDate)
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
            }(),
            onLogContact: { print("Log contact") },
            onCall: { print("Call") },
            onMessage: { print("Message") }
        )

        FriendCard(
            friend: {
                let f = Friend(name: "Marcus Johnson", reminderIntervalDays: 7)
                f.lastContactedAt = Calendar.current.date(byAdding: .day, value: -5, to: Date())
                return f
            }(),
            onLogContact: { print("Log contact") }
        )

        FriendCard(
            friend: {
                let f = Friend(name: "Emma Wilson", reminderIntervalDays: 30)
                f.lastContactedAt = Date()
                return f
            }(),
            onLogContact: { print("Log contact") },
            onCall: { print("Call") },
            onMessage: { print("Message") }
        )
    }
    .padding()
    .background(Color.warmGray)
}
