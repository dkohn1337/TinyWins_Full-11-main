import SwiftUI

// MARK: - Animated Stat Box

/// Animated stat display with counting number effect.
struct AnimatedStatBox: View {
    let value: Int
    let label: String
    let icon: String
    let gradient: [Color]
    var prefix: String = ""
    var animate: Bool = false

    @State private var displayValue: Int = 0

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient.map { $0.opacity(0.2) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("\(prefix)\(displayValue)")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .contentTransition(.numericText())

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .onAppear {
            if animate {
                withAnimation(.easeOut(duration: 0.8)) {
                    displayValue = value
                }
            } else {
                displayValue = value
            }
        }
        .onChange(of: value) { _, newValue in
            withAnimation(.easeOut(duration: 0.3)) {
                displayValue = newValue
            }
        }
    }
}

// MARK: - Stat Pill

/// Compact stat badge with colored background.
struct StatPill: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 14, weight: .bold))
            Text(label)
                .font(.system(size: 12))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

// MARK: - Insight Highlight Card

/// Card for displaying a highlighted insight with tip.
struct InsightHighlightCard: View {
    let icon: String
    let iconGradient: [Color]
    let title: String
    let subtitle: String
    let detail: String
    let tip: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: iconGradient.map { $0.opacity(0.2) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(
                            LinearGradient(
                                colors: iconGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    Text(subtitle)
                        .font(.system(size: 17, weight: .semibold))

                    Text(detail)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Tip
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)

                Text(tip)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.yellow.opacity(0.1))
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

// MARK: - Aha Insight Card

/// Card for displaying an "aha moment" insight with entrance animation, expand/collapse, and share.
struct AhaInsightCard: View {
    let icon: String
    let gradient: [Color]
    let title: String
    let message: String
    let actionable: String?
    var index: Int = 0  // For staggered animation
    var expandedContent: String? = nil  // Optional extra content when expanded

    @State private var hasAppeared = false
    @State private var showSparkle = false
    @State private var isExpanded = false
    @State private var showingShareSheet = false

    /// Generate shareable text for this insight
    private var shareText: String {
        var text = "💡 \(title)\n\n\(message)"
        if let actionable = actionable {
            text += "\n\n✨ \(actionable)"
        }
        text += "\n\n— Shared from TinyWins"
        return text
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient.map { $0.opacity(0.2) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Sparkle effect overlay
                    if showSparkle {
                        Image(systemName: "sparkle")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(gradient.first ?? .purple)
                            .offset(x: 14, y: -14)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))

                    Text(message)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(isExpanded ? nil : 3)

                    if let actionable = actionable {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 11))
                            Text(actionable)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding(.top, 4)
                    }

                    // Expanded content
                    if isExpanded, let expandedContent = expandedContent {
                        Text(expandedContent)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                Spacer()

                // Action buttons column
                VStack(spacing: 8) {
                    // Share button
                    Button(action: {
                        showingShareSheet = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)

                    // Expand/collapse button (if there's extra content or long message)
                    if expandedContent != nil || message.count > 100 {
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                isExpanded.toggle()
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }) {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(14)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6))
        )
        // Entrance animation
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.92)
        .offset(y: hasAppeared ? 0 : 10)
        .onAppear {
            // Staggered animation based on index
            let delay = Double(index) * 0.1
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                hasAppeared = true
            }
            // Show sparkle briefly after card appears
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.3) {
                withAnimation(.spring(response: 0.3)) {
                    showSparkle = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.8) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showSparkle = false
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            InsightShareSheet(items: [shareText])
        }
    }
}

// MARK: - Insight Share Sheet Helper

private struct InsightShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Plus Feature Item

/// Feature list item for Plus upsell.
struct PlusFeatureItem: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 20)

            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.green)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Locked Insight Preview Card

/// Blurred/locked preview card for Free users showing premium content they're missing.
struct LockedInsightPreviewCard: View {
    let title: String
    let previewText: String
    let icon: String
    var gradient: [Color] = [.purple, .pink]
    let onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient.map { $0.opacity(0.15) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 16, weight: .bold))

                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    Text("Plus Feature")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.purple)
                }

                Spacer()
            }

            // Blurred preview content
            ZStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray4))
                            .frame(width: 80, height: 14)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(width: 60, height: 14)
                    }
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 12)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 200, height: 12)
                }
                .padding(12)
                .blur(radius: 4)

                // Preview text overlay
                Text(previewText)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(10)

            // Unlock button
            Button(action: onUnlock) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Get TinyWins+")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: gradient.map { $0.opacity(0.3) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

// MARK: - Period Chip

/// Selectable period chip for time range selection.
struct PeriodChip: View {
    let period: InsightPeriod
    let isSelected: Bool
    let isLocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                }
                Text(period.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                    LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing) :
                    LinearGradient(colors: [Color(.systemGray5)], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundColor(isSelected ? .white : (isLocked ? .secondary : .primary))
            .cornerRadius(20)
            .shadow(color: isSelected ? .purple.opacity(0.3) : .clear, radius: 6, y: 3)
        }
    }
}

// MARK: - Legacy Supporting Views (kept for compatibility)

struct EnhancedInsightStatBox: View {
    let value: Int
    let label: String
    let icon: String
    let gradient: [Color]
    var prefix: String = ""
    var animate: Bool = false

    @State private var displayValue: Int = 0

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient.map { $0.opacity(0.2) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("\(prefix)\(displayValue)")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6))
        )
        .onAppear {
            if animate {
                withAnimation(.easeOut(duration: 0.8)) {
                    displayValue = value
                }
            } else {
                displayValue = value
            }
        }
        .onChange(of: value) { _, newValue in
            withAnimation(.easeOut(duration: 0.3)) {
                displayValue = newValue
            }
        }
    }
}

struct EnhancedInsightRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct PlusFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 20)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.green)
        }
    }
}

// MARK: - Premium Insight Teaser Card

/// Blurred preview card showing what Free users are missing with Plus insights.
/// Shows a tantalizing glimpse of premium analytics to encourage upgrades.
struct PremiumInsightTeaserCard: View {
    let onUnlock: () -> Void

    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.2), .pink.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 18))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Premium Insights")
                            .font(.system(size: 16, weight: .bold))

                        Text("PLUS")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple, .pink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }

                    Text("Deeper patterns you're missing")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Blurred preview rows (simulating premium content)
            VStack(spacing: 10) {
                // Row 1: Time pattern preview
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "clock.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.blue.opacity(0.5))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemGray4))
                            .frame(width: 120, height: 12)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemGray5))
                            .frame(width: 80, height: 10)
                    }

                    Spacer()
                }

                // Row 2: Trend preview
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 14))
                                .foregroundColor(.green.opacity(0.5))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemGray4))
                            .frame(width: 100, height: 12)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemGray5))
                            .frame(width: 140, height: 10)
                    }

                    Spacer()
                }

                // Row 3: Pattern preview
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "sparkles")
                                .font(.system(size: 14))
                                .foregroundColor(.orange.opacity(0.5))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemGray4))
                            .frame(width: 90, height: 12)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemGray5))
                            .frame(width: 110, height: 10)
                    }

                    Spacer()
                }
            }
            .padding(12)
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(12)
            .blur(radius: 2)
            .overlay(
                // "What you're missing" overlay
                VStack(spacing: 4) {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                    Text("Unlock to see your patterns")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            )

            // Feature highlights
            HStack(spacing: 16) {
                FeatureHighlight(icon: "clock.fill", text: "Time patterns")
                FeatureHighlight(icon: "chart.bar.fill", text: "30-day trends")
                FeatureHighlight(icon: "brain.head.profile", text: "AI insights")
            }

            // CTA Button
            Button(action: onUnlock) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Unlock Premium Insights")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.3), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerOffset)
                        .mask(RoundedRectangle(cornerRadius: 12))
                )
                .shadow(color: .purple.opacity(0.4), radius: 8, y: 4)
            }
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    shimmerOffset = 200
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    LinearGradient(
                        colors: [.purple.opacity(0.3), .pink.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

/// Small feature highlight used in the teaser card.
private struct FeatureHighlight: View {
    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.purple)
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Try 30-Day View Suggestion

/// Contextual suggestion banner for users who have been active 4+ weeks,
/// encouraging them to try the 30-day view (Plus feature).
struct Try30DayViewSuggestion: View {
    let onTryNow: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 12) {
            // Main banner
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.2), .cyan.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)

                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 16))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Ready for the bigger picture?")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)

                            Text("NEW")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.blue)
                                )
                        }

                        Text("You've been using TinyWins for 4+ weeks")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                VStack(spacing: 14) {
                    // What you'll see
                    HStack(spacing: 10) {
                        VStack(spacing: 8) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                            Text("Monthly\ntrends")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                            Text("Pattern\nhistory")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 20))
                                .foregroundColor(.purple)
                            Text("Deeper\ninsights")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 8)

                    // CTA
                    Button(action: onTryNow) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Try 30-Day View")
                                .font(.system(size: 14, weight: .semibold))
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                    }

                    Text("Included with Plus")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.08), .cyan.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    LinearGradient(
                        colors: [.blue.opacity(0.2), .cyan.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}
