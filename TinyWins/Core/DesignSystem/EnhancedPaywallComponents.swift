import SwiftUI

// MARK: - Enhanced Paywall Components
// Premium subscription UI components

// MARK: - Premium Hero Section

/// Top section of paywall with premium messaging
struct PaywallHeroSection: View {
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        VStack(spacing: 20) {
            // Premium badge banner
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundColor(.purple)
                Text("TinyWins Plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.purple)
                Image(systemName: "star.fill")
                    .foregroundColor(.purple)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.purple.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset)
                    .mask(Capsule())
            )
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    shimmerOffset = 200
                }
            }

            // Main headline
            Text("Unlock Your Parenting Superpower")
                .font(.system(size: 32, weight: .black))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            // Community message
            VStack(spacing: 12) {
                // Avatar stack (decorative)
                HStack(spacing: -12) {
                    ForEach(0..<5, id: \.self) { index in
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: avatarColors[index],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(Color(.systemBackground), lineWidth: 3)
                            )
                    }

                    Circle()
                        .fill(Color(.systemGray4))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(Color(.systemBackground), lineWidth: 3)
                        )
                }

                Text("Join mindful parents everywhere")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }

    private let avatarColors: [[Color]] = [
        [.blue, .cyan],
        [.purple, .pink],
        [.orange, .yellow],
        [.green, .mint],
        [.red, .orange]
    ]
}

// MARK: - Feature List Section

/// Premium features with value stacking
struct PaywallFeatureList: View {
    let features: [PremiumFeature]

    struct PremiumFeature: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let description: String
        let value: String
        let gradient: [Color]
    }

    private var totalValue: Double {
        features.compactMap { Double($0.value.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: "/mo", with: "")) }.reduce(0, +)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("What You're Missing")
                .font(.system(size: 26, weight: .bold))

            VStack(spacing: 12) {
                ForEach(features) { feature in
                    PaywallFeatureRow(feature: feature)
                }
            }

            // Value stack summary
            VStack(spacing: 8) {
                Divider()
                    .padding(.vertical, 8)

                HStack {
                    Text("Total Value:")
                        .font(.system(size: 16, weight: .medium))
                    Spacer()
                    Text("$\(String(format: "%.2f", totalValue))/month")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                        .strikethrough()
                }

                HStack {
                    Text("Your Price:")
                        .font(.system(size: 18, weight: .semibold))
                    Spacer()
                    Text("$9.99/month")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemGray6))
        )
    }
}

/// Individual feature row
struct PaywallFeatureRow: View {
    let feature: PaywallFeatureList.PremiumFeature

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: feature.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: feature.gradient[0].opacity(0.4), radius: 8)

                Image(systemName: feature.icon)
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.system(size: 17, weight: .bold))
                Text(feature.description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Value
            Text(feature.value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .strikethrough()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
        )
    }
}

// MARK: - Pricing Plans Section

/// Plan selection cards
struct PaywallPricingSection: View {
    @Binding var selectedPlan: PricingPlan

    enum PricingPlan: String, CaseIterable {
        case monthly = "Monthly"
        case annual = "Annual"

        var price: String {
            switch self {
            case .monthly: return "$9.99"
            case .annual: return "$59.99"
            }
        }

        var billingCycle: String {
            switch self {
            case .monthly: return "/month"
            case .annual: return "/year"
            }
        }

        var monthlyEquivalent: String? {
            switch self {
            case .monthly: return nil
            case .annual: return "$4.99/mo"
            }
        }

        var savings: String? {
            switch self {
            case .monthly: return nil
            case .annual: return "Save 50%"
            }
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(.system(size: 26, weight: .bold))

            // Annual plan (recommended)
            PaywallPlanCard(
                plan: .annual,
                isSelected: selectedPlan == .annual,
                isPopular: true
            ) {
                selectedPlan = .annual
                HapticManager.shared.selection()
            }

            // Monthly plan
            PaywallPlanCard(
                plan: .monthly,
                isSelected: selectedPlan == .monthly,
                isPopular: false
            ) {
                selectedPlan = .monthly
                HapticManager.shared.selection()
            }
        }
    }
}

/// Individual plan card
struct PaywallPlanCard: View {
    let plan: PaywallPricingSection.PricingPlan
    let isSelected: Bool
    let isPopular: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Popular badge
                if isPopular {
                    Text("BEST VALUE")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8, corners: [.topLeft, .topRight])
                }

                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(plan.rawValue)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)

                        if let savings = plan.savings {
                            Text(savings)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.green)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(plan.price)
                                .font(.system(size: 32, weight: .black))
                            Text(plan.billingCycle)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }

                        if let monthly = plan.monthlyEquivalent {
                            Text(monthly)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(20)

                // Selection indicator
                if isSelected {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Selected")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.green)
                    }
                    .padding(.bottom, 16)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: isPopular ? 0 : 20)
                    .fill(isSelected ? Color.purple.opacity(0.1) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: isPopular ? 0 : 20)
                            .strokeBorder(
                                isSelected ?
                                    LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                    LinearGradient(colors: [Color(.systemGray4)], startPoint: .top, endPoint: .bottom),
                                lineWidth: isSelected ? 3 : 1
                            )
                    )
            )
            .cornerRadius(20)
            .shadow(color: isSelected ? .purple.opacity(0.2) : .black.opacity(0.06), radius: isSelected ? 16 : 8, y: isSelected ? 8 : 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Testimonials Carousel

/// Social proof testimonials
struct PaywallTestimonialsSection: View {
    let testimonials: [Testimonial]
    @State private var currentIndex = 0

    struct Testimonial: Identifiable {
        let id = UUID()
        let quote: String
        let author: String
        let rating: Int
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Loved by Parents")
                .font(.system(size: 26, weight: .bold))

            TabView(selection: $currentIndex) {
                ForEach(Array(testimonials.enumerated()), id: \.element.id) { index, testimonial in
                    TestimonialCardView(
                        quote: testimonial.quote,
                        author: testimonial.author,
                        rating: testimonial.rating
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 180)
        }
    }
}

// MARK: - Guarantee Section

/// Money-back guarantee badge
struct PaywallGuaranteeSection: View {
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.green)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("7-Day Money-Back Guarantee")
                    .font(.system(size: 18, weight: .bold))

                Text("Try risk-free. Cancel anytime, no questions asked.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.green.opacity(0.1))
        )
    }
}

// MARK: - CTA Button Section

/// Primary call-to-action with urgency
struct PaywallCTASection: View {
    let selectedPlan: PaywallPricingSection.PricingPlan
    let deadline: Date?
    let onStartTrial: () -> Void
    let onRestorePurchases: () -> Void

    @State private var buttonScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 16) {
            // Main CTA button
            Button(action: {
                HapticManager.shared.success()
                onStartTrial()
            }) {
                VStack(spacing: 6) {
                    Text("Start Free Trial")
                        .font(.system(size: 22, weight: .black))

                    Text("Then \(selectedPlan.price)\(selectedPlan.billingCycle) after 7 days")
                        .font(.system(size: 14))
                        .opacity(0.9)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(20)
                .shadow(color: .purple.opacity(0.5), radius: 20, y: 10)
                .scaleEffect(buttonScale)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    buttonScale = 1.03
                }
            }

            // Urgency countdown
            if let deadline = deadline {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.red)
                    Text("Offer expires in")
                        .foregroundColor(.secondary)
                    UrgencyTimerView(targetDate: deadline, label: nil)
                }
                .font(.system(size: 14, weight: .semibold))
            }

            // Fine print
            Text("Auto-renews. Cancel anytime.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            // Restore purchases
            Button(action: onRestorePurchases) {
                Text("Restore Purchases")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Complete Paywall View

/// Full paywall screen composition
struct EnhancedPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PaywallPricingSection.PricingPlan = .annual

    let onPurchase: (PaywallPricingSection.PricingPlan) -> Void
    let onRestore: () -> Void

    private let features: [PaywallFeatureList.PremiumFeature] = [
        .init(icon: "brain.head.profile", title: "AI-Powered Insights", description: "Personalized coaching based on your family patterns", value: "$19.99/mo", gradient: [.purple, .pink]),
        .init(icon: "chart.line.uptrend.xyaxis", title: "Predictive Analytics", description: "Anticipate challenging moments before they happen", value: "$14.99/mo", gradient: [.blue, .cyan]),
        .init(icon: "shield.fill", title: "Streak Protection", description: "Never lose your hard-earned streak again", value: "$9.99/mo", gradient: [.orange, .yellow]),
        .init(icon: "person.2.fill", title: "Family Sharing", description: "Sync with co-parents in real-time", value: "$12.99/mo", gradient: [.green, .mint]),
        .init(icon: "paintbrush.fill", title: "More ways to personalize", description: "Includes Forest, Midnight, and Lavender themes", value: "$7.99/mo", gradient: [.pink, .purple])
    ]

    private let testimonials: [PaywallTestimonialsSection.Testimonial] = [
        .init(quote: "This app changed how I see my kids. I notice so much more of the good now.", author: "Sarah M.", rating: 5),
        .init(quote: "The streak feature keeps me accountable. I actually look forward to logging moments.", author: "Michael R.", rating: 5),
        .init(quote: "Worth every penny. My relationship with my daughter has never been better.", author: "Jennifer L.", rating: 5)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    PaywallHeroSection()

                    PaywallFeatureList(features: features)
                        .padding(.horizontal, 20)

                    PaywallPricingSection(selectedPlan: $selectedPlan)
                        .padding(.horizontal, 20)

                    PaywallTestimonialsSection(testimonials: testimonials)
                        .padding(.horizontal, 20)

                    PaywallGuaranteeSection()
                        .padding(.horizontal, 20)

                    PaywallCTASection(
                        selectedPlan: selectedPlan,
                        deadline: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
                        onStartTrial: { onPurchase(selectedPlan) },
                        onRestorePurchases: onRestore
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .padding(.top, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Helper Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Previews

#Preview("Full Paywall") {
    EnhancedPaywallView(
        onPurchase: { _ in },
        onRestore: {}
    )
}

#Preview("Hero Section") {
    PaywallHeroSection()
        .padding()
}

#Preview("Pricing Section") {
    PaywallPricingSection(selectedPlan: .constant(.annual))
        .padding()
}
