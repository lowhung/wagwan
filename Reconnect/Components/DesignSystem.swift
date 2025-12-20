import SwiftUI

// MARK: - Color Palette

extension Color {
    // Primary warm colors
    static let coral = Color(red: 1.0, green: 0.459, blue: 0.459)
    static let coralLight = Color(red: 1.0, green: 0.631, blue: 0.631)
    static let coralDark = Color(red: 0.847, green: 0.329, blue: 0.329)

    // Secondary colors
    static let sage = Color(red: 0.627, green: 0.757, blue: 0.651)
    static let sageLight = Color(red: 0.776, green: 0.878, blue: 0.800)
    static let sageDark = Color(red: 0.471, green: 0.616, blue: 0.494)

    static let lavender = Color(red: 0.710, green: 0.651, blue: 0.843)
    static let lavenderLight = Color(red: 0.847, green: 0.808, blue: 0.929)
    static let lavenderDark = Color(red: 0.573, green: 0.494, blue: 0.745)

    static let sunflower = Color(red: 1.0, green: 0.835, blue: 0.380)
    static let sunflowerLight = Color(red: 1.0, green: 0.902, blue: 0.580)
    static let sunflowerDark = Color(red: 0.898, green: 0.718, blue: 0.220)

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

// MARK: - Avatar Colors

extension Friend {
    var avatarColor: Color {
        let colors: [Color] = [.coral, .sage, .lavender, .sunflower]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }
}
