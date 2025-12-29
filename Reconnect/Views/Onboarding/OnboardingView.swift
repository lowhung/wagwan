import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentPage = 0
    @State private var showCelebration = false
    @State private var isTransitioning = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            illustration: .connection,
            title: "Stay Connected",
            subtitle:
                "Life gets busy. Reconnect helps you remember to reach out to the friends who matter most."
        ),
        OnboardingPage(
            illustration: .reminders,
            title: "Gentle Reminders",
            subtitle:
                "Set personalized schedules for each friend. Get nudged when it's time to say hello."
        ),
        OnboardingPage(
            illustration: .progress,
            title: "Track Your Progress",
            subtitle:
                "See at a glance who's overdue, who's due soon, and celebrate your connections."
        ),
        OnboardingPage(
            illustration: .calendar,
            title: "Calendar Integration",
            subtitle: "Create calendar events that link back to Reconnect for seamless scheduling."
        ),
    ]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        pageView(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? .none : .gentleBounce, value: currentPage)

                // Bottom section
                VStack(spacing: Spacing.lg) {
                    // Page indicators - playful hearts with progress trail
                    PageIndicator(
                        pageCount: pages.count,
                        currentPage: currentPage,
                        reduceMotion: reduceMotion
                    )

                    // Buttons
                    if currentPage == pages.count - 1 {
                        PrimaryButton("Get Started", icon: "arrow.right") {
                            completeOnboarding()
                        }
                    } else {
                        HStack(spacing: Spacing.md) {
                            Button("Skip") {
                                completeOnboarding()
                            }
                            .font(.headlineSmall)
                            .foregroundStyle(Color.textSecondary)
                            .frame(maxWidth: .infinity)

                            PrimaryButton("Next", icon: "arrow.right") {
                                withAnimation(reduceMotion ? .none : .gentleBounce) {
                                    currentPage += 1
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }

            // Transition overlay
            if isTransitioning {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .confettiCelebration(
            isActive: $showCelebration,
            message: "You're all set!",
            duration: 1.5
        )
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Animated illustration
            AnimatedIllustration(
                type: page.illustration,
                reduceMotion: reduceMotion
            )
            .frame(width: 200, height: 200)

            // Text
            VStack(spacing: Spacing.md) {
                Text(page.title)
                    .font(.displayMedium)
                    .foregroundStyle(Color.warmBlack)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()
            Spacer()
        }
    }

    private func completeOnboarding() {
        HapticService.shared.celebrate()
        showCelebration = true

        // Delay the transition to let the celebration play
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.3 : 1.2)) {
            withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.5)) {
                isTransitioning = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                hasCompletedOnboarding = true
            }
        }
    }
}

// MARK: - Onboarding Page Model

private enum IllustrationType {
    case connection
    case reminders
    case progress
    case calendar
}

private struct OnboardingPage {
    let illustration: IllustrationType
    let title: String
    let subtitle: String
}

// MARK: - Animated Illustrations

private struct AnimatedIllustration: View {
    let type: IllustrationType
    let reduceMotion: Bool

    var body: some View {
        switch type {
        case .connection:
            ConnectionIllustration(reduceMotion: reduceMotion)
        case .reminders:
            RemindersIllustration(reduceMotion: reduceMotion)
        case .progress:
            ProgressIllustration(reduceMotion: reduceMotion)
        case .calendar:
            CalendarIllustration(reduceMotion: reduceMotion)
        }
    }
}

// Two friends connecting with floating hearts
private struct ConnectionIllustration: View {
    let reduceMotion: Bool
    @State private var heartsVisible = false
    @State private var avatarOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.coral.opacity(0.1))
                .frame(width: 180, height: 180)

            // Two avatar circles
            HStack(spacing: -20) {
                // Left avatar
                ZStack {
                    Circle()
                        .fill(Color.sage.opacity(0.3))
                        .frame(width: 70, height: 70)
                    Text("👋")
                        .font(.system(size: 30))
                }
                .offset(x: reduceMotion ? 0 : -avatarOffset)

                // Right avatar
                ZStack {
                    Circle()
                        .fill(Color.lavender.opacity(0.3))
                        .frame(width: 70, height: 70)
                    Text("😊")
                        .font(.system(size: 30))
                }
                .offset(x: reduceMotion ? 0 : avatarOffset)
            }

            // Floating hearts
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: "heart.fill")
                    .font(.system(size: CGFloat(12 + index * 4)))
                    .foregroundStyle(Color.coral.opacity(0.7))
                    .offset(
                        x: CGFloat([-30, 0, 25][index]),
                        y: CGFloat([-60, -80, -55][index])
                    )
                    .opacity(heartsVisible ? 1 : 0)
                    .scaleEffect(heartsVisible ? 1 : 0.5)
                    .animation(
                        reduceMotion
                            ? .none
                            : .spring(response: 0.6, dampingFraction: 0.6).delay(
                                Double(index) * 0.15),
                        value: heartsVisible
                    )
            }
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    avatarOffset = 5
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                heartsVisible = true
            }
        }
    }
}

// Bell with notification animation
private struct RemindersIllustration: View {
    let reduceMotion: Bool
    @State private var bellRotation: Double = 0
    @State private var showNotification = false

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.sunflower.opacity(0.1))
                .frame(width: 180, height: 180)

            // Bell
            ZStack {
                Image(systemName: "bell.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(Color.sunflower)
                    .rotationEffect(.degrees(bellRotation))

                // Notification badge
                Circle()
                    .fill(Color.coral)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text("!")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .offset(x: 25, y: -25)
                    .scaleEffect(showNotification ? 1 : 0)
                    .animation(
                        reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.5),
                        value: showNotification)
            }

            // Sound waves
            ForEach(0..<2, id: \.self) { index in
                SoundWave(delay: Double(index) * 0.3, reduceMotion: reduceMotion)
                    .offset(x: 50, y: -10)
            }
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 0.15).repeatCount(6, autoreverses: true)) {
                    bellRotation = 15
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    bellRotation = 0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showNotification = true
            }
        }
    }
}

private struct SoundWave: View {
    let delay: Double
    let reduceMotion: Bool
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.8

    var body: some View {
        Circle()
            .stroke(Color.sunflower.opacity(0.5), lineWidth: 2)
            .frame(width: 30, height: 30)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(
                    .easeOut(duration: 1.0).delay(delay).repeatForever(autoreverses: false)
                ) {
                    scale = 2.0
                    opacity = 0
                }
            }
    }
}

// Progress chart with filling bars
private struct ProgressIllustration: View {
    let reduceMotion: Bool
    @State private var barHeights: [CGFloat] = [0, 0, 0, 0]
    private let targetHeights: [CGFloat] = [40, 60, 45, 80]

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.sage.opacity(0.1))
                .frame(width: 180, height: 180)

            // Chart
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(0..<4, id: \.self) { index in
                    VStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(barColors[index])
                            .frame(width: 28, height: barHeights[index])
                    }
                }
            }
            .frame(height: 100, alignment: .bottom)

            // Happy face on top bar
            Text("✨")
                .font(.system(size: 24))
                .offset(x: 42, y: -55)
                .opacity(barHeights[3] > 60 ? 1 : 0)
                .animation(reduceMotion ? .none : .spring, value: barHeights[3])
        }
        .onAppear {
            for index in 0..<4 {
                let delay = Double(index) * 0.15
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(
                        reduceMotion ? .none : .spring(response: 0.6, dampingFraction: 0.7)
                    ) {
                        barHeights[index] = targetHeights[index]
                    }
                }
            }
        }
    }

    private var barColors: [Color] {
        [.coral.opacity(0.7), .sunflower.opacity(0.7), .lavender.opacity(0.7), .sage]
    }
}

// Calendar with flipping pages
private struct CalendarIllustration: View {
    let reduceMotion: Bool
    @State private var showHearts = false
    @State private var currentDay = 1

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.lavender.opacity(0.1))
                .frame(width: 180, height: 180)

            // Calendar
            VStack(spacing: 0) {
                // Header
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.lavender)
                    .frame(width: 100, height: 28)
                    .overlay(
                        Text("RECONNECT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    )

                // Body
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white)
                    .frame(width: 100, height: 70)
                    .overlay(
                        Text("\(currentDay)")
                            .font(.system(size: 36, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.warmBlack)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }

            // Floating hearts around calendar
            ForEach(0..<4, id: \.self) { index in
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.coral.opacity(0.6))
                    .offset(
                        x: CGFloat([50, -55, 45, -50][index]),
                        y: CGFloat([-20, 10, 30, -35][index])
                    )
                    .opacity(showHearts ? 1 : 0)
                    .scaleEffect(showHearts ? 1 : 0)
                    .animation(
                        reduceMotion
                            ? .none
                            : .spring(response: 0.5, dampingFraction: 0.6).delay(
                                Double(index) * 0.1 + 0.3),
                        value: showHearts
                    )
            }
        }
        .onAppear {
            showHearts = true
            guard !reduceMotion else { return }
            // Animate through a few days
            for i in 1...3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.4) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        currentDay = [1, 8, 15, 22][i]
                    }
                }
            }
        }
    }
}

// MARK: - Page Indicator

private struct PageIndicator: View {
    let pageCount: Int
    let currentPage: Int
    let reduceMotion: Bool

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(0..<pageCount, id: \.self) { index in
                HeartIndicator(
                    isActive: index == currentPage,
                    isPast: index < currentPage,
                    reduceMotion: reduceMotion
                )
            }
        }
    }
}

private struct HeartIndicator: View {
    let isActive: Bool
    let isPast: Bool
    let reduceMotion: Bool

    @State private var bounceScale: CGFloat = 1.0

    var body: some View {
        Image(systemName: isPast || isActive ? "heart.fill" : "heart")
            .font(.system(size: isActive ? 18 : 14))
            .foregroundStyle(heartColor)
            .scaleEffect(bounceScale)
            .animation(reduceMotion ? .none : .bounce, value: isActive)
            .onChange(of: isActive) { _, newValue in
                if newValue && !reduceMotion {
                    // Bounce animation when becoming active
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        bounceScale = 1.3
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            bounceScale = 1.0
                        }
                    }
                }
            }
    }

    private var heartColor: Color {
        if isActive {
            return .coral
        } else if isPast {
            return .coral.opacity(0.6)
        } else {
            return .coral.opacity(0.3)
        }
    }
}

#Preview {
    OnboardingView()
}
