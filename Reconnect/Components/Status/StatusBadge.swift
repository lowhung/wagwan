import SwiftUI

struct StatusBadge: View {
    let status: ContactStatus

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false
    @State private var iconScale: CGFloat = 1.0

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
            ZStack {
                // Pulse effect for overdue
                if status == .overdue && !reduceMotion {
                    Circle()
                        .fill(color.opacity(0.3))
                        .frame(width: 16, height: 16)
                        .scaleEffect(isPulsing ? 1.5 : 1.0)
                        .opacity(isPulsing ? 0 : 0.6)
                }

                Image(systemName: icon)
                    .font(.labelSmall)
                    .scaleEffect(iconScale)
            }
            .frame(width: 16, height: 16)

            Text(status.label)
                .font(.labelMedium)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs + 2)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Status: \(status.label)")
        .onAppear {
            startAnimations()
        }
        .onChange(of: status) { _, _ in
            animateStatusChange()
        }
    }

    private func startAnimations() {
        guard !reduceMotion else { return }

        if status == .overdue {
            // Continuous subtle pulse for overdue
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                isPulsing = true
            }
        }
    }

    private func animateStatusChange() {
        guard !reduceMotion else { return }

        // Pop animation when status changes
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            iconScale = 1.3
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                iconScale = 1.0
            }
        }

        // Reset and restart pulse if now overdue
        isPulsing = false
        if status == .overdue {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                startAnimations()
            }
        }
    }
}

// MARK: - Compact Badge (just the dot)

struct StatusDot: View {
    let status: ContactStatus

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    private var color: Color {
        switch status {
        case .overdue: return .statusOverdue
        case .dueSoon: return .statusDueSoon
        case .onTrack: return .statusOnTrack
        }
    }

    var body: some View {
        ZStack {
            if status == .overdue && !reduceMotion {
                Circle()
                    .fill(color.opacity(0.4))
                    .frame(width: 10, height: 10)
                    .scaleEffect(isPulsing ? 2.0 : 1.0)
                    .opacity(isPulsing ? 0 : 0.5)
            }

            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
        }
        .onAppear {
            guard !reduceMotion && status == .overdue else { return }
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                isPulsing = true
            }
        }
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
