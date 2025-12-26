import SwiftUI

// MARK: - Confetti Particle

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGPoint
    var rotation: Double
    var rotationSpeed: Double
    var color: Color
    var size: CGSize
    var shape: ConfettiShape
    var opacity: Double = 1.0

    enum ConfettiShape: CaseIterable {
        case circle
        case rectangle
        case triangle
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    let isActive: Bool
    var particleCount: Int = 50
    var duration: Double = 1.5
    var onComplete: (() -> Void)?

    @State private var particles: [ConfettiParticle] = []
    @State private var animationProgress: Double = 0

    // Pastel colors from the design system
    private let confettiColors: [Color] = [
        .coral,
        .sage,
        .lavender,
        .sunflower,
        .coralLight,
        .sageLight,
        .lavenderLight,
        .sunflowerLight,
    ]

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1 / 60)) { timeline in
                Canvas { context, size in
                    for particle in particles {
                        let rect = CGRect(
                            x: particle.position.x - particle.size.width / 2,
                            y: particle.position.y - particle.size.height / 2,
                            width: particle.size.width,
                            height: particle.size.height
                        )

                        context.opacity = particle.opacity

                        var contextCopy = context
                        contextCopy.translateBy(x: particle.position.x, y: particle.position.y)
                        contextCopy.rotate(by: .degrees(particle.rotation))
                        contextCopy.translateBy(x: -particle.position.x, y: -particle.position.y)

                        switch particle.shape {
                        case .circle:
                            contextCopy.fill(
                                Circle().path(in: rect),
                                with: .color(particle.color)
                            )
                        case .rectangle:
                            contextCopy.fill(
                                RoundedRectangle(cornerRadius: 2).path(in: rect),
                                with: .color(particle.color)
                            )
                        case .triangle:
                            let path = Path { p in
                                p.move(to: CGPoint(x: rect.midX, y: rect.minY))
                                p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                                p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                                p.closeSubpath()
                            }
                            contextCopy.fill(path, with: .color(particle.color))
                        }
                    }
                }
            }
            .onChange(of: isActive) { oldValue, newValue in
                if newValue && !oldValue {
                    startAnimation(in: geometry.size)
                }
            }
            .onAppear {
                if isActive {
                    startAnimation(in: geometry.size)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func startAnimation(in size: CGSize) {
        // Generate particles from the top center with burst effect
        let centerX = size.width / 2
        let startY = size.height * 0.3

        particles = (0..<particleCount).map { _ in
            let angle = Double.random(in: -Double.pi * 0.8 ... -Double.pi * 0.2)
            let speed = Double.random(in: 300...600)

            return ConfettiParticle(
                position: CGPoint(
                    x: centerX + CGFloat.random(in: -30...30),
                    y: startY + CGFloat.random(in: -20...20)
                ),
                velocity: CGPoint(
                    x: cos(angle) * speed * Double.random(in: 0.5...1.5),
                    y: sin(angle) * speed
                ),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -360...360),
                color: confettiColors.randomElement() ?? .coral,
                size: CGSize(
                    width: CGFloat.random(in: 6...12),
                    height: CGFloat.random(in: 6...12)
                ),
                shape: ConfettiParticle.ConfettiShape.allCases.randomElement() ?? .rectangle
            )
        }

        animationProgress = 0

        // Animate particles
        let startTime = Date()
        let timer = Timer.scheduledTimer(withTimeInterval: 1 / 60, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = elapsed / duration

            if progress >= 1.0 {
                timer.invalidate()
                particles = []
                onComplete?()
                return
            }

            let deltaTime = 1.0 / 60.0
            let gravity: Double = 800

            for i in particles.indices {
                // Update position
                particles[i].position.x += particles[i].velocity.x * deltaTime
                particles[i].position.y += particles[i].velocity.y * deltaTime

                // Apply gravity
                particles[i].velocity.y += gravity * deltaTime

                // Apply air resistance
                particles[i].velocity.x *= 0.99
                particles[i].velocity.y *= 0.99

                // Update rotation
                particles[i].rotation += particles[i].rotationSpeed * deltaTime

                // Fade out in the last 30% of the animation
                if progress > 0.7 {
                    let fadeProgress = (progress - 0.7) / 0.3
                    particles[i].opacity = 1.0 - fadeProgress
                }
            }
        }

        RunLoop.main.add(timer, forMode: .common)
    }
}

// MARK: - Celebratory Message Overlay

struct CelebratoryOverlay: View {
    let message: String
    let isShowing: Bool

    var body: some View {
        if isShowing {
            VStack {
                Spacer()

                Text(message)
                    .font(.headlineMedium)
                    .foregroundStyle(Color.warmBlack)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                    .background(
                        Capsule()
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
                    )
                    .transition(.scale.combined(with: .opacity))

                Spacer()
                    .frame(height: 100)
            }
        }
    }
}

// MARK: - Confetti Celebration Modifier

struct ConfettiCelebration: ViewModifier {
    @Binding var isActive: Bool
    var message: String = "Great job staying connected!"
    var duration: Double = 1.5
    var onComplete: (() -> Void)?

    @State private var showMessage = false

    func body(content: Content) -> some View {
        content
            .overlay {
                ZStack {
                    ConfettiView(
                        isActive: isActive,
                        duration: duration
                    ) {
                        isActive = false
                        showMessage = false
                        onComplete?()
                    }

                    CelebratoryOverlay(
                        message: message,
                        isShowing: showMessage
                    )
                }
                .ignoresSafeArea()
            }
            .onChange(of: isActive) { oldValue, newValue in
                if newValue {
                    withAnimation(.bounce) {
                        showMessage = true
                    }

                    // Hide message slightly before confetti ends
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.8) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showMessage = false
                        }
                    }
                }
            }
    }
}

extension View {
    func confettiCelebration(
        isActive: Binding<Bool>,
        message: String = "Great job staying connected!",
        duration: Double = 1.5,
        onComplete: (() -> Void)? = nil
    ) -> some View {
        modifier(
            ConfettiCelebration(
                isActive: isActive,
                message: message,
                duration: duration,
                onComplete: onComplete
            ))
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var showConfetti = false

        var body: some View {
            ZStack {
                Color.warmGray.ignoresSafeArea()

                VStack {
                    Button("Celebrate!") {
                        showConfetti = true
                    }
                    .font(.headlineLarge)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(Color.coral)
                    .clipShape(Capsule())
                }
            }
            .confettiCelebration(isActive: $showConfetti)
        }
    }

    return PreviewWrapper()
}
