import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "heart.fill",
            iconColor: .coral,
            title: "Stay Connected",
            subtitle: "Life gets busy. Reconnect helps you remember to reach out to the friends who matter most."
        ),
        OnboardingPage(
            icon: "bell.fill",
            iconColor: .sunflower,
            title: "Gentle Reminders",
            subtitle: "Set personalized schedules for each friend. Get nudged when it's time to say hello."
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            iconColor: .sage,
            title: "Track Your Progress",
            subtitle: "See at a glance who's overdue, who's due soon, and celebrate your connections."
        ),
        OnboardingPage(
            icon: "calendar.badge.plus",
            iconColor: .lavender,
            title: "Calendar Integration",
            subtitle: "Create calendar events that link back to Reconnect for seamless scheduling."
        )
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
                    // Page indicators
                    HStack(spacing: Spacing.xs) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.coral : Color.coral.opacity(0.3))
                                .frame(width: index == currentPage ? 10 : 8, height: index == currentPage ? 10 : 8)
                                .animation(reduceMotion ? .none : .bounce, value: currentPage)
                        }
                    }

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
        }
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
        HapticService.shared.success()
        withAnimation(reduceMotion ? .none : .gentleBounce) {
            hasCompletedOnboarding = true
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

#Preview {
    OnboardingView()
}
