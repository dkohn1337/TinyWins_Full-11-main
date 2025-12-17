import SwiftUI

/// Celebration view for reflection streak milestones
struct StreakMilestoneView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    let streak: Int
    let onDismiss: () -> Void

    @State private var animationPhase: Int = 0
    @State private var showConfetti = false
    @State private var pulseGlow = false
    @State private var streakPulse = false

    private var isPlusSubscriber: Bool {
        subscriptionManager.effectiveIsPlusSubscriber
    }

    private var milestone: Milestone {
        Milestone.forStreak(streak)
    }

    var body: some View {
        ZStack {
            // Background
            milestone.backgroundColor
                .ignoresSafeArea()

            // Confetti overlay
            if showConfetti {
                ConfettiOverlay()
            }

            // Content
            VStack(spacing: 24) {
                Spacer()

                // Animated icon with pulsing glow
                ZStack {
                    // Outer glow pulse
                    if animationPhase >= 2 {
                        Circle()
                            .fill(milestone.iconBackground.opacity(0.3))
                            .frame(width: 160, height: 160)
                            .scaleEffect(pulseGlow ? 1.1 : 0.9)
                            .opacity(pulseGlow ? 0.3 : 0.6)
                            .blur(radius: 8)
                    }

                    Circle()
                        .fill(milestone.iconBackground)
                        .frame(width: 120, height: 120)
                        .scaleEffect(animationPhase >= 1 ? 1.0 : 0.5)
                        .opacity(animationPhase >= 1 ? 1.0 : 0.0)
                        .shadow(color: milestone.iconBackground.opacity(0.5), radius: pulseGlow ? 20 : 10, y: 0)

                    Image(systemName: milestone.icon)
                        .font(.system(size: 56))
                        .foregroundStyle(milestone.iconGradient)
                        .scaleEffect(animationPhase >= 2 ? 1.0 : 0.3)
                        .rotationEffect(.degrees(animationPhase >= 2 ? 0 : -30))
                        .symbolEffect(.bounce, options: .repeating.speed(0.5), value: animationPhase >= 3)
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animationPhase)

                // Title
                Text(milestone.title)
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)
                    .opacity(animationPhase >= 3 ? 1.0 : 0.0)
                    .offset(y: animationPhase >= 3 ? 0 : 20)
                    .animation(.spring(response: 0.4).delay(0.1), value: animationPhase)

                // Streak count with pulse
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .symbolEffect(.variableColor.iterative, options: .repeating, value: streakPulse)
                    Text("\(streak) days")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(25)
                .scaleEffect(streakPulse ? 1.05 : 1.0)
                .shadow(color: .orange.opacity(streakPulse ? 0.4 : 0.2), radius: streakPulse ? 10 : 5, y: 2)
                .opacity(animationPhase >= 3 ? 1.0 : 0.0)
                .animation(.spring(response: 0.4).delay(0.2), value: animationPhase)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: streakPulse)

                // Message
                Text(milestone.message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(animationPhase >= 4 ? 1.0 : 0.0)
                    .animation(.spring(response: 0.4).delay(0.3), value: animationPhase)

                // Plus upsell or bonus for Plus users
                if !isPlusSubscriber && milestone.isPlusMilestone {
                    plusUpsellCard
                        .opacity(animationPhase >= 4 ? 1.0 : 0.0)
                        .animation(.spring(response: 0.4).delay(0.4), value: animationPhase)
                } else if isPlusSubscriber && milestone.plusBonusMessage != nil {
                    plusBonusCard
                        .opacity(animationPhase >= 4 ? 1.0 : 0.0)
                        .animation(.spring(response: 0.4).delay(0.4), value: animationPhase)
                }

                Spacer()

                // Continue button
                Button(action: {
                    dismiss()
                    onDismiss()
                }) {
                    Text("Keep Going!")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(milestone.buttonGradient)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .opacity(animationPhase >= 5 ? 1.0 : 0.0)
                .animation(.spring(response: 0.4).delay(0.5), value: animationPhase)

                Spacer()
                    .frame(height: 40)
            }
        }
        .onAppear {
            runAnimation()
        }
    }

    @State private var showingPaywall = false

    // MARK: - Plus Upsell Card

    private var plusUpsellCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("Unlock More with Plus")
                    .font(.subheadline.weight(.semibold))
            }

            Text("Get personalized insights, full history, and month-in-review summaries.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Upgrade CTA button
            Button(action: {
                showingPaywall = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Get TinyWins+")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.purple.opacity(0.1), .pink.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    LinearGradient(
                        colors: [.purple.opacity(0.3), .pink.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .cornerRadius(12)
        .padding(.horizontal, 24)
        .sheet(isPresented: $showingPaywall) {
            PlusPaywallView(context: .reflectionHistory)
        }
    }

    // MARK: - Plus Bonus Card

    private var plusBonusCard: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundColor(.purple)
                Text(milestone.plusBonusMessage ?? "")
                    .font(.subheadline.weight(.medium))
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.purple.opacity(0.15), .pink.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
        .padding(.horizontal, 24)
    }

    // MARK: - Animation

    private func runAnimation() {
        // Initial haptic for celebration start
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Stagger the animation phases
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            animationPhase = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animationPhase = 2
            // Start the glow pulse
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseGlow = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animationPhase = 3
            showConfetti = true
            // Success haptic for milestone reveal
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            // Start streak pulse
            streakPulse = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            animationPhase = 4
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            animationPhase = 5
            // Light haptic for button appearance
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

// MARK: - Milestone Configuration

struct Milestone {
    let days: Int
    let title: String
    let message: String
    let icon: String
    let isPlusMilestone: Bool
    let plusBonusMessage: String?

    var backgroundColor: Color {
        Color(.systemBackground)
    }

    var iconBackground: Color {
        switch days {
        case 7: return .orange.opacity(0.15)
        case 14: return .purple.opacity(0.15)
        case 30: return .indigo.opacity(0.15)
        default: return .blue.opacity(0.15)
        }
    }

    var iconGradient: LinearGradient {
        switch days {
        case 7:
            return LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
        case 14:
            return LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom)
        case 30:
            return LinearGradient(colors: [.indigo, .purple], startPoint: .top, endPoint: .bottom)
        default:
            return LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom)
        }
    }

    var buttonGradient: LinearGradient {
        switch days {
        case 7:
            return LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
        case 14:
            return LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
        case 30:
            return LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)
        default:
            return LinearGradient(colors: [.accentColor, .accentColor.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
        }
    }

    static func forStreak(_ streak: Int) -> Milestone {
        switch streak {
        case 7:
            return Milestone(
                days: 7,
                title: "One Week Strong!",
                message: "You've shown up for yourself 7 days in a row. That's the foundation of a powerful habit.",
                icon: "star.fill",
                isPlusMilestone: false,
                plusBonusMessage: nil
            )
        case 14:
            return Milestone(
                days: 14,
                title: "Two Weeks!",
                message: "14 days of self-reflection. You're proving that you're committed to being the best parent you can be.",
                icon: "trophy.fill",
                isPlusMilestone: true,
                plusBonusMessage: "Your full reflection history is now available!"
            )
        case 30:
            return Milestone(
                days: 30,
                title: "One Month!",
                message: "30 days of consistent reflection. You're not just building a habit - you're transforming your parenting journey.",
                icon: "crown.fill",
                isPlusMilestone: true,
                plusBonusMessage: "Your Month in Review is ready to view!"
            )
        default:
            return Milestone(
                days: streak,
                title: "\(streak) Days!",
                message: "Keep up the amazing work. Every day of reflection makes a difference.",
                icon: "flame.fill",
                isPlusMilestone: false,
                plusBonusMessage: nil
            )
        }
    }

    static let celebrationMilestones = [7, 14, 30]
}

// MARK: - Confetti Overlay

private struct ConfettiOverlay: View {
    @State private var particles: [StreakConfettiParticle] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                generateParticles(in: geo.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func generateParticles(in size: CGSize) {
        let colors: [Color] = [.orange, .yellow, .pink, .purple, .blue, .green]

        for i in 0..<50 {
            let particle = StreakConfettiParticle(
                id: i,
                color: colors.randomElement() ?? .orange,
                size: CGFloat.random(in: 4...10),
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                targetY: size.height + 50,
                opacity: 1.0
            )
            particles.append(particle)

            // Animate each particle
            withAnimation(.easeIn(duration: Double.random(in: 1.5...3.0)).delay(Double(i) * 0.03)) {
                if let index = particles.firstIndex(where: { $0.id == i }) {
                    particles[index].position.y = particles[index].targetY
                    particles[index].opacity = 0.0
                }
            }
        }
    }
}

private struct StreakConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var position: CGPoint
    let targetY: CGFloat
    var opacity: Double
}

// MARK: - Preview

#Preview("7 Day Milestone") {
    StreakMilestoneView(streak: 7) { }
        .environmentObject(SubscriptionManager.shared)
}

#Preview("30 Day Milestone") {
    StreakMilestoneView(streak: 30) { }
        .environmentObject(SubscriptionManager.shared)
}
