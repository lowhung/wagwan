import SwiftUI

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let color: Color
    var isLoading: Bool = false
    var action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false

    init(
        _ title: String,
        icon: String? = nil,
        color: Color = .coral,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: {
            if !isLoading {
                HapticService.shared.buttonTap()
                action()
            }
        }) {
            HStack(spacing: Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.headlineSmall)
                    }
                    Text(title)
                        .font(.headlineMedium)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(color)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .scaleEffect(
                x: isPressed ? 0.96 : 1.0,
                y: isPressed ? 0.98 : 1.0
            )
            .brightness(isPressed ? 0.05 : 0)
            .opacity(isLoading ? 0.8 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(reduceMotion ? .none : .spring(response: 0.25, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Secondary Button

struct SecondaryButton: View {
    let title: String
    let icon: String?
    let color: Color
    var action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false

    init(
        _ title: String,
        icon: String? = nil,
        color: Color = .coral,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticService.shared.buttonTap()
            action()
        }) {
            HStack(spacing: Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.headlineSmall)
                }
                Text(title)
                    .font(.headlineMedium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(color.opacity(isPressed ? 0.25 : 0.15))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .scaleEffect(
                x: isPressed ? 0.96 : 1.0,
                y: isPressed ? 0.98 : 1.0
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(reduceMotion ? .none : .spring(response: 0.25, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Icon Button

struct IconButton: View {
    let icon: String
    let color: Color
    var size: CGFloat = 44
    var accessibilityLabel: String?
    var action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticService.shared.buttonTap()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .semibold))
                .frame(width: size, height: size)
                .background(color.opacity(isPressed ? 0.25 : 0.15))
                .foregroundStyle(color)
                .clipShape(Circle())
                .scaleEffect(isPressed ? 0.85 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel ?? icon)
        .accessibilityAddTraits(.isButton)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(reduceMotion ? .none : .spring(response: 0.25, dampingFraction: 0.5)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        PrimaryButton("Add Friend", icon: "plus") {}
        PrimaryButton("Call Now", icon: "phone.fill", color: .sage) {}
        SecondaryButton("Skip", icon: "arrow.right") {}

        HStack(spacing: Spacing.md) {
            IconButton(icon: "phone.fill", color: .sage) {}
            IconButton(icon: "message.fill", color: .lavender) {}
            IconButton(icon: "envelope.fill", color: .sunflower) {}
        }
    }
    .padding()
}
