import SwiftUI

// MARK: - Color Palette

extension Color {
    // Primary warm colors - softCoral #F4A6A0 (warmer, less saturated pink-coral)
    static let coral = Color(red: 0.957, green: 0.651, blue: 0.627)
    static let coralLight = Color(red: 0.973, green: 0.776, blue: 0.757)
    static let coralDark = Color(red: 0.839, green: 0.533, blue: 0.514)

    // Secondary colors - dustySage #A8C5B5 (more muted, sophisticated)
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

    // Neutral colors
    static let warmGray = Color(red: 0.933, green: 0.918, blue: 0.902)
    static let warmGrayDark = Color(red: 0.467, green: 0.439, blue: 0.412)
    static let warmBlack = Color(red: 0.2, green: 0.18, blue: 0.16)

    // Status colors
    static let statusOverdue = coral
    static let statusDueSoon = sunflower
    static let statusOnTrack = sage
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
}

// MARK: - Animation Presets

extension Animation {
    static let bounce = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let gentleBounce = Animation.spring(response: 0.5, dampingFraction: 0.7)
    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.8)
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
            .cardShadow()
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

// MARK: - Gradients

extension LinearGradient {
    /// Subtle warm background gradient from cream to white
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

// MARK: - Avatar Colors

extension Friend {
    var avatarColor: Color {
        let colors: [Color] = [.coral, .sage, .lavender, .sunflower]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }
}
