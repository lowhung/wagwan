import SwiftUI
import UIKit

// MARK: - Adaptive Color Palette

extension Color {
    // MARK: - Primary Warm Colors

    // softCoral #F4A6A0 (warmer, less saturated pink-coral)
    static let coral = Color(red: 0.957, green: 0.651, blue: 0.627)
    static let coralLight = Color(red: 0.973, green: 0.776, blue: 0.757)
    static let coralDark = Color(red: 0.839, green: 0.533, blue: 0.514)

    // dustySage #A8C5B5 (more muted, sophisticated)
    static let sage = Color(red: 0.659, green: 0.773, blue: 0.710)
    static let sageLight = Color(red: 0.784, green: 0.863, blue: 0.816)
    static let sageDark = Color(red: 0.533, green: 0.659, blue: 0.600)

    // softLavender #E6DFF5 (slightly softer)
    static let lavender = Color(red: 0.902, green: 0.875, blue: 0.961)
    static let lavenderLight = Color(red: 0.941, green: 0.925, blue: 0.976)
    static let lavenderDark = Color(red: 0.749, green: 0.710, blue: 0.855)

    // goldenHoney #F5D78E (warmer, less harsh yellow)
    static let sunflower = Color(red: 0.961, green: 0.843, blue: 0.557)
    static let sunflowerLight = Color(red: 0.976, green: 0.902, blue: 0.706)
    static let sunflowerDark = Color(red: 0.863, green: 0.733, blue: 0.420)

    // mutedRose #C98B8B (soft rose for delete/remove actions)
    static let rose = Color(red: 0.788, green: 0.545, blue: 0.545)

    // MARK: - Adaptive Semantic Colors

    /// Primary background - warm cream in light, warm dark in dark mode
    static let appBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.10, blue: 0.09, alpha: 1.0)  // warm black #1C1A17
            : UIColor(red: 0.933, green: 0.918, blue: 0.902, alpha: 1.0)  // warmGray
    })

    /// Card/surface background - white in light, warm dark gray in dark mode
    static let cardBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.16, green: 0.14, blue: 0.13, alpha: 1.0)  // warm gray dark #282421
            : UIColor.white
    })

    /// Elevated surface - for sheets and modals
    static let elevatedBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.20, green: 0.18, blue: 0.16, alpha: 1.0)  // slightly lighter #332E29
            : UIColor(red: 0.933, green: 0.918, blue: 0.902, alpha: 1.0)  // warmGray
    })

    /// Primary text color - adapts for readability
    static let textPrimary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.933, green: 0.918, blue: 0.902, alpha: 1.0)  // warmGray (light text)
            : UIColor(red: 0.2, green: 0.18, blue: 0.16, alpha: 1.0)  // warmBlack
    })

    /// Secondary text color - muted
    static let textSecondary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.6, green: 0.57, blue: 0.54, alpha: 1.0)  // lighter warm gray
            : UIColor(red: 0.467, green: 0.439, blue: 0.412, alpha: 1.0)  // warmGrayDark
    })

    // MARK: - Legacy Neutral Colors (for backwards compatibility)

    static let warmGray = Color(red: 0.933, green: 0.918, blue: 0.902)
    static let warmGrayDark = Color(red: 0.467, green: 0.439, blue: 0.412)
    static let warmBlack = Color(red: 0.2, green: 0.18, blue: 0.16)

    // MARK: - Status Colors (slightly brighter in dark mode for visibility)

    static let statusOverdue = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.98, green: 0.70, blue: 0.67, alpha: 1.0)  // brighter coral
            : UIColor(red: 0.957, green: 0.651, blue: 0.627, alpha: 1.0)  // coral
    })

    static let statusDueSoon = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.98, green: 0.88, blue: 0.60, alpha: 1.0)  // brighter sunflower
            : UIColor(red: 0.961, green: 0.843, blue: 0.557, alpha: 1.0)  // sunflower
    })

    static let statusOnTrack = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.70, green: 0.82, blue: 0.76, alpha: 1.0)  // brighter sage
            : UIColor(red: 0.659, green: 0.773, blue: 0.710, alpha: 1.0)  // sage
    })
}

// MARK: - Typography

extension Font {
    static let displayLarge = Font.system(size: 34, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)
    static let displaySmall = Font.system(size: 22, weight: .semibold, design: .rounded)

    static let headlineLarge = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headlineMedium = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let headlineSmall = Font.system(size: 15, weight: .semibold, design: .rounded)

    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .rounded)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .rounded)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .rounded)

    static let labelLarge = Font.system(size: 14, weight: .medium, design: .rounded)
    static let labelMedium = Font.system(size: 12, weight: .medium, design: .rounded)
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .rounded)
}

// MARK: - Spacing

enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

enum CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xl: CGFloat = 24
    static let full: CGFloat = 9999
}

// MARK: - Shadows

extension View {
    func cardShadow() -> some View {
        self.shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    func softShadow() -> some View {
        self.shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    /// Adaptive shadow that's more subtle in dark mode
    func adaptiveShadow() -> some View {
        self.modifier(AdaptiveShadowModifier())
    }
}

private struct AdaptiveShadowModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content.shadow(
            color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08),
            radius: colorScheme == .dark ? 4 : 8,
            x: 0,
            y: colorScheme == .dark ? 2 : 4
        )
    }
}

// MARK: - Animation Presets

extension Animation {
    static let bounce = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let gentleBounce = Animation.spring(response: 0.5, dampingFraction: 0.7)
    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.8)
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08),
                radius: colorScheme == .dark ? 4 : 8,
                x: 0,
                y: colorScheme == .dark ? 2 : 4
            )
    }
}

struct PillStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.labelMedium)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func pillStyle(color: Color) -> some View {
        modifier(PillStyle(color: color))
    }
}

// MARK: - Adaptive Gradients

extension LinearGradient {
    /// Subtle warm background gradient - adapts to color scheme
    static func warmBackground(for colorScheme: ColorScheme) -> LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.13, green: 0.12, blue: 0.11),  // warm dark
                    Color(red: 0.11, green: 0.10, blue: 0.09),  // slightly darker
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.996, green: 0.976, blue: 0.949),  // cream
                    Color.white,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    /// Legacy light mode gradient (for compatibility)
    static var warmBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.996, green: 0.976, blue: 0.949),  // cream
                Color.white,
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Accent gradient for CTAs - coral to lavender
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [Color.coral, Color.lavender],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Subtle gradient for selected/highlighted states
    static var selectedGradient: LinearGradient {
        LinearGradient(
            colors: [Color.coral.opacity(0.9), Color.coralLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension RadialGradient {
    /// Soft glow effect for avatars and cards
    static func avatarGlow(color: Color) -> RadialGradient {
        RadialGradient(
            colors: [color.opacity(0.3), color.opacity(0.0)],
            center: .center,
            startRadius: 0,
            endRadius: 40
        )
    }

    /// Subtle card glow effect
    static var cardGlow: RadialGradient {
        RadialGradient(
            colors: [
                Color.coral.opacity(0.05),
                Color.clear,
            ],
            center: .center,
            startRadius: 0,
            endRadius: 100
        )
    }
}

// MARK: - Adaptive Background View

struct AdaptiveBackground: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        LinearGradient.warmBackground(for: colorScheme)
            .ignoresSafeArea()
    }
}

// MARK: - Avatar Colors

extension Friend {
    var avatarColor: Color {
        let colors: [Color] = [.coral, .sage, .lavender, .sunflower]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }
}
