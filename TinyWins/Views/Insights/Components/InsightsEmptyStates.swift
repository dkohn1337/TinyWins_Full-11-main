import SwiftUI

// MARK: - Insights Empty State View

/// Empty state shown when no children have been added
struct InsightsEmptyStateView: View {
    @Binding var animateStats: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Animated icon with glow
                ZStack {
                    // Outer glow rings
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.purple.opacity(0.3 - Double(i) * 0.1), .blue.opacity(0.2 - Double(i) * 0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 120 + CGFloat(i) * 30, height: 120 + CGFloat(i) * 30)
                            .scaleEffect(animateStats ? 1.0 : 0.8)
                            .opacity(animateStats ? 1.0 : 0.0)
                            .animation(.spring(response: 0.8).delay(Double(i) * 0.1), value: animateStats)
                    }

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.purple.opacity(0.25), .blue.opacity(0.1), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)

                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 52))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.pulse, options: .repeating)
                }
                .padding(.top, 16)

                VStack(spacing: 14) {
                    Text("No Kids Yet")
                        .font(.system(size: 26, weight: .bold))

                    Text("Add your first child to start seeing family insights and patterns over time.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 28)
            }
            .padding()
            .padding(.bottom, 120)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Insights No Data State View

/// Empty state shown when children exist but no behavior events logged
struct InsightsNoDataStateView: View {
    @Binding var animateStats: Bool
    let eventCount: Int

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Animated sparkle icon
                ZStack {
                    // Floating particles
                    ForEach(0..<6, id: \.self) { i in
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 8, height: 8)
                            .offset(
                                x: CGFloat.random(in: -50...50),
                                y: CGFloat.random(in: -50...50)
                            )
                            .opacity(animateStats ? 0.6 : 0.0)
                            .scaleEffect(animateStats ? 1.0 : 0.0)
                            .animation(
                                .spring(response: 0.6)
                                .delay(Double(i) * 0.1)
                                .repeatForever(autoreverses: true),
                                value: animateStats
                            )
                    }

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.purple.opacity(0.3), .purple.opacity(0.05)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)

                    Image(systemName: "sparkles")
                        .font(.system(size: 52))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.pulse, options: .repeating)
                }
                .padding(.top, 16)

                VStack(spacing: 14) {
                    Text("Start Logging Moments")
                        .font(.system(size: 26, weight: .bold))

                    Text("Log a few positive moments and note any challenges. Insights will appear as patterns emerge.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 28)

                // Progress hint card
                ProgressHintCardView(eventCount: eventCount)
            }
            .padding()
            .padding(.bottom, 120)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Progress Hint Card View

/// Card showing progress toward first insight unlock
struct ProgressHintCardView: View {
    let eventCount: Int

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.yellow)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Unlock Your First Insight")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Log 5 moments to see patterns")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))

                    let progress = min(CGFloat(eventCount) / 5.0, 1.0)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 8)

            Text("\(eventCount)/5 moments logged")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        .padding(.horizontal, 24)
    }
}

// MARK: - Insights Toolbar Button

/// Styled toolbar button for insights view
struct InsightsToolbarButton: View {
    let icon: String
    let gradient: [Color]
    var highlighted: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(highlighted ? Color.purple.opacity(0.15) : Color(.systemGray6))
                .frame(width: 36, height: 36)
            Image(systemName: icon)
                .font(.system(size: gradient.count > 1 ? 14 : 15, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}

// MARK: - Previews

#Preview("Empty State") {
    InsightsEmptyStateView(animateStats: .constant(true))
}

#Preview("No Data State") {
    InsightsNoDataStateView(animateStats: .constant(true), eventCount: 2)
}

#Preview("Progress Hint") {
    ProgressHintCardView(eventCount: 3)
        .padding()
}
