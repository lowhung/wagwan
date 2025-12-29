import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentPage = 0
    @State private var showCelebration = false
    @State private var isTransitioning = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "heart.fill",
            iconColor: .coral,
            title: "Stay Connected",
            subtitle:
                "Life gets busy. Reconnect helps you remember to reach out to the friends who matter most."
        ),
        OnboardingPage(
            icon: "bell.fill",
            iconColor: .sunflower,
            title: "Gentle Reminders",
            subtitle:
                "Set personalized schedules for each friend. Get nudged when it's time to say hello."
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            iconColor: .sage,
            title: "Track Your Progress",
            subtitle:
                "See at a glance who's overdue, who's due soon, and celebrate your connections."
        ),
        OnboardingPage(
            icon: "calendar.badge.plus",
            iconColor: .lavender,
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

            // Icon
            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.15))
                    .frame(width: 140, height: 140)

                Image(systemName: page.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(page.iconColor)
            }

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

private struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
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
