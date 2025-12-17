import SwiftUI
import StoreKit

// MARK: - Demo Mode Types (file-private for DemoPricingCard access)

private enum DemoPlan: String {
    case monthly, yearly

    var displayPrice: String {
        switch self {
        case .monthly: return "$4.99"
        case .yearly: return "$29.99"
        }
    }

    var periodText: String {
        switch self {
        case .monthly: return "month"
        case .yearly: return "year"
        }
    }

    var monthlyEquivalent: String {
        switch self {
        case .monthly: return "$4.99"
        case .yearly: return "$2.50"
        }
    }

    var savings: Int? {
        switch self {
        case .monthly: return nil
        case .yearly: return 50
        }
    }
}

/// Context for what triggered the paywall
enum PaywallContext {
    case generic
    case addChild
    case additionalGoals
    case advancedInsights
    case extendedHistory
    case coParent
    case premiumThemes
    case reflectionHistory
    case childLimitReached(count: Int)

    var contextMessage: String? {
        switch self {
        case .generic:
            return nil
        case .addChild:
            return "Upgrade to track up to 5 children"
        case .additionalGoals:
            return "Upgrade to set up to 3 active goals per child"
        case .advancedInsights:
            return "Upgrade to unlock heatmaps, trends, and AI insights"
        case .extendedHistory:
            return "Upgrade to access your complete history"
        case .coParent:
            return "Upgrade to sync with a co-parent"
        case .premiumThemes:
            return "Upgrade to unlock Forest, Midnight, and Lavender themes"
        case .reflectionHistory:
            return "Upgrade to access your full reflection history"
        case .childLimitReached(let count):
            return "You're tracking \(count) child\(count == 1 ? "" : "ren"). Upgrade for up to 5."
        }
    }

    var contextIcon: String {
        switch self {
        case .generic: return "sparkles"
        case .addChild, .childLimitReached: return "figure.2.and.child.holdinghands"
        case .additionalGoals: return "star.circle.fill"
        case .advancedInsights: return "chart.line.uptrend.xyaxis"
        case .extendedHistory: return "calendar.badge.clock"
        case .coParent: return "person.2.fill"
        case .premiumThemes: return "paintpalette.fill"
        case .reflectionHistory: return "moon.stars.fill"
        }
    }
}

/// The main TinyWins Plus paywall screen - Enhanced with game psychology
struct PlusPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    // Optional context for what triggered the paywall
    var context: PaywallContext = .generic

    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""

    // Demo mode state
    @State private var selectedDemoPlan: DemoPlan = .yearly

    #if DEBUG
    private var isDemoMode: Bool {
        UserPreferencesStore().showDemoPaywall
    }
    #else
    private var isDemoMode: Bool { false }
    #endif

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Context banner (if triggered from specific feature)
                    if let message = context.contextMessage {
                        contextBanner(message: message, icon: context.contextIcon)
                    }

                    // Enhanced Header with social proof
                    headerSection

                    // Value-stacked features
                    featuresSection

                    // Comparison table (Free vs Plus)
                    comparisonTable

                    // Pricing options with visual selection
                    pricingSection

                    // Guarantee section
                    guaranteeSection

                    // Enhanced purchase button with urgency
                    purchaseButton

                    // Restore and terms
                    footerSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .alert("Something went wrong", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .accessibilityIdentifier(InsightsAccessibilityIdentifiers.paywallRoot)
        .onAppear {
            // Select yearly by default
            if selectedProduct == nil {
                selectedProduct = subscriptionManager.yearlyProduct ?? subscriptionManager.monthlyProduct
            }
        }
    }

    // MARK: - Context Banner

    private func contextBanner(message: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [.purple.opacity(0.1), .pink.opacity(0.08)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .pink.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 20) {
            // Warm, simple badge
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                Text("TinyWins Plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.pink.opacity(0.1))
            )

            // Softer, warmer headline
            VStack(spacing: 4) {
                Text("Notice More,")
                    .font(.system(size: 28, weight: .bold))
                Text("Together")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .multilineTextAlignment(.center)

            // Warm subtitle without generic social proof
            Text("More features for families who want to celebrate every small win")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Social proof section
            SocialProofSection()
                .padding(.top, 8)
        }
        .padding(.top, 16)
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(spacing: 20) {
            Text("Plus Features")
                .font(.system(size: 26, weight: .bold))

            VStack(spacing: 12) {
                FeatureRow(
                    icon: "figure.2.and.child.holdinghands",
                    title: "Your Whole Family",
                    description: "Track up to 5 children, each with their own wins, goals, and growth story",
                    gradient: [.purple, .pink]
                )

                FeatureRow(
                    icon: "star.circle.fill",
                    title: "More Goals, More Wins",
                    description: "3 active goals per child means more moments to celebrate together",
                    gradient: [.orange, .yellow]
                )

                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "See the Bigger Picture",
                    description: "6 months of insights reveal patterns you would not notice day to day",
                    gradient: [.blue, .cyan]
                )

                FeatureRow(
                    icon: "sparkles",
                    title: "Advanced Insights",
                    description: "Patterns and progress over time to see what is working",
                    gradient: [.indigo, .purple]
                )

                FeatureRow(
                    icon: "person.2.fill",
                    title: "Co-Parent Sync",
                    description: "Both parents notice together, even from different locations",
                    gradient: [.pink, .purple]
                )

                FeatureRow(
                    icon: "calendar.badge.clock",
                    title: "A Year of Memories",
                    description: "Your complete 365-day history to see how far they have come",
                    gradient: [.green, .mint]
                )

                FeatureRow(
                    icon: "paintpalette.fill",
                    title: "More ways to personalize",
                    description: "Includes Forest, Midnight, and Lavender themes",
                    gradient: [.cyan, .teal]
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - Comparison Table

    private var comparisonTable: some View {
        VStack(spacing: 16) {
            Text("Free vs Plus")
                .font(.system(size: 22, weight: .bold))

            VStack(spacing: 0) {
                // Header row
                HStack {
                    Text("Feature")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Free")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 60)
                    Text("Plus")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 60)
                        .foregroundColor(.purple)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))

                // Comparison rows
                ComparisonRow(feature: "Children", free: "1", plus: "5")
                ComparisonRow(feature: "Active goals per child", free: "1", plus: "3")
                ComparisonRow(feature: "History", free: "7 days", plus: "1 year")
                ComparisonRow(feature: "Advanced insights", free: false, plus: true)
                ComparisonRow(feature: "Heatmaps & trends", free: false, plus: true)
                ComparisonRow(feature: "Co-parent sync", free: false, plus: true)
                ComparisonRow(feature: "Premium themes", free: false, plus: true)
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(.system(size: 26, weight: .bold))

            // Demo mode: show mock pricing cards
            if isDemoMode {
                demoPricingCards
            } else if subscriptionManager.isLoading && subscriptionManager.products.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading plans...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if subscriptionManager.products.isEmpty {
                // Better empty state with retry option
                VStack(spacing: 16) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)

                    Text("Unable to load plans")
                        .font(.headline)

                    Text("Please check your internet connection and try again.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button(action: {
                        Task {
                            await subscriptionManager.loadProducts()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.purple)
                        .cornerRadius(20)
                    }
                }
                .padding()
            } else {
                // Yearly plan first (recommended)
                if let yearlyProduct = subscriptionManager.yearlyProduct {
                    // Calculate actual savings dynamically
                    let actualSavings = yearlyProduct.savingsPercentage(comparedTo: subscriptionManager.monthlyProduct)
                    PricingCard(
                        product: yearlyProduct,
                        isSelected: selectedProduct?.id == yearlyProduct.id,
                        isPopular: true,
                        savings: actualSavings
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedProduct = yearlyProduct
                        }
                    }
                }

                // Monthly plan
                if let monthlyProduct = subscriptionManager.monthlyProduct {
                    PricingCard(
                        product: monthlyProduct,
                        isSelected: selectedProduct?.id == monthlyProduct.id,
                        isPopular: false,
                        savings: nil
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedProduct = monthlyProduct
                        }
                    }
                }
            }
        }
    }

    // MARK: - Demo Pricing Cards

    private var demoPricingCards: some View {
        VStack(spacing: 12) {
            // Demo banner
            HStack(spacing: 6) {
                Image(systemName: "hammer.fill")
                    .font(.caption)
                Text("DEMO MODE")
                    .font(.caption.weight(.bold))
            }
            .foregroundColor(.orange)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.15))
            .cornerRadius(8)

            // Yearly demo card
            DemoPricingCard(
                plan: .yearly,
                isSelected: selectedDemoPlan == .yearly,
                isPopular: true
            ) {
                withAnimation(.spring(response: 0.3)) {
                    selectedDemoPlan = .yearly
                }
            }

            // Monthly demo card
            DemoPricingCard(
                plan: .monthly,
                isSelected: selectedDemoPlan == .monthly,
                isPopular: false
            ) {
                withAnimation(.spring(response: 0.3)) {
                    selectedDemoPlan = .monthly
                }
            }
        }
    }

    // MARK: - Guarantee Section

    private var guaranteeSection: some View {
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
                Text("7-Day Free Trial")
                    .font(.system(size: 18, weight: .bold))

                Text("Try everything free for 7 days. Cancel anytime.")
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

    @State private var shimmerOffset: CGFloat = -300

    // MARK: - Enhanced Purchase Button

    private var purchaseButton: some View {
        VStack(spacing: 12) {
            // In demo mode, always show active button
            if isDemoMode {
                demoPurchaseButton
            } else {
                Button(action: purchase) {
                    ZStack {
                        VStack(spacing: 6) {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                // Trial badge
                                HStack(spacing: 6) {
                                    Image(systemName: "gift.fill")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("7-DAY FREE TRIAL")
                                        .font(.system(size: 12, weight: .black))
                                        .tracking(1)
                                }
                                .foregroundColor(.yellow)
                                .padding(.bottom, 2)

                                Text("Start Free Trial")
                                    .font(.system(size: 24, weight: .black))

                                if let product = selectedProduct {
                                    Text("Then \(product.displayPrice)/\(product.subscriptionPeriodText)")
                                        .font(.system(size: 14))
                                        .opacity(0.9)
                                }
                            }
                        }
                        .foregroundColor(.white)

                        // Shimmer overlay
                        if selectedProduct != nil && !isPurchasing {
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.3), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 100)
                            .offset(x: shimmerOffset)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .background(
                        selectedProduct == nil ?
                            LinearGradient(colors: [Color(.systemGray4)], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: selectedProduct == nil ? .clear : .purple.opacity(0.5), radius: 20, y: 10)
                    .clipped()
                }
                .disabled(selectedProduct == nil || isPurchasing)
                .onAppear {
                    withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                        shimmerOffset = 300
                    }
                }
            }

            // Apple-required subscription disclosure
            VStack(spacing: 4) {
                if isDemoMode {
                    Text("After your 7-day free trial, \(selectedDemoPlan.displayPrice) will be charged to your Apple ID account. Subscription automatically renews \(selectedDemoPlan == .yearly ? "yearly" : "monthly") unless canceled at least 24 hours before the end of the current period.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else if let product = selectedProduct {
                    Text("After your free trial, \(product.displayPrice) will be charged to your Apple ID. Subscription renews \(product.renewalPeriodText) unless you cancel at least 24 hours before the current period ends.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }

                HStack(spacing: 16) {
                    Link("Terms of Service", destination: URL(string: AppLinks.termsOfServiceURL)!)
                        .font(.system(size: 12, weight: .medium))
                    Link("Privacy Policy", destination: URL(string: AppLinks.privacyPolicyURL)!)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.blue)
            }
            .padding(.horizontal, 8)
        }
    }

    // Demo purchase button (always active, shows demo flow)
    private var demoPurchaseButton: some View {
        Button(action: demoPurchase) {
            VStack(spacing: 6) {
                Text("Start free trial")
                    .font(.system(size: 22, weight: .black))

                Text("Then \(selectedDemoPlan.displayPrice)/\(selectedDemoPlan.periodText)")
                    .font(.system(size: 14))
                    .opacity(0.9)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(20)
            .shadow(color: .purple.opacity(0.5), radius: 20, y: 10)
        }
    }

    private func demoPurchase() {
        // Show demo success alert
        errorMessage = "Demo Mode: In production, this would start a 7-day free trial for the \(selectedDemoPlan == .yearly ? "Yearly" : "Monthly") plan at \(selectedDemoPlan.displayPrice)/\(selectedDemoPlan.periodText)."
        showingError = true
    }

    // MARK: - Footer

    private var footerSection: some View {
        Button("Restore Purchases") {
            Task {
                await subscriptionManager.restorePurchases()
                if subscriptionManager.isPlusSubscriber {
                    dismiss()
                }
            }
        }
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(.blue)
        .accessibilityLabel("Restore previous purchases")
    }
    
    // MARK: - Actions
    
    private func purchase() {
        guard let product = selectedProduct else { return }
        
        isPurchasing = true
        
        Task {
            do {
                let success = try await subscriptionManager.purchase(product)
                if success {
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            isPurchasing = false
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    var subtitle: String? = nil
    let gradient: [Color]
    var index: Int = 0  // For staggered animation

    @State private var hasAppeared = false

    var body: some View {
        HStack(spacing: 16) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: gradient[0].opacity(0.4), radius: 8)
                    .scaleEffect(hasAppeared ? 1.0 : 0.5)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .symbolEffect(.bounce, options: .speed(0.5), value: hasAppeared)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))

                    // "Coming soon" or other subtitle badge
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.purple.opacity(0.8))
                            )
                    }
                }
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(hasAppeared ? 1 : 0)
            .offset(x: hasAppeared ? 0 : 20)

            Spacer()

            // Checkmark to indicate included
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)
                .opacity(hasAppeared ? 1 : 0)
                .scaleEffect(hasAppeared ? 1 : 0.5)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
        )
        .onAppear {
            let delay = Double(index) * 0.1
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                hasAppeared = true
            }
        }
    }
}

// MARK: - Social Proof Section

private struct SocialProofSection: View {
    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 16) {
            // Stats row
            HStack(spacing: 20) {
                StatBadge(value: "10K+", label: "Families", icon: "house.fill")
                StatBadge(value: "50K+", label: "Wins Logged", icon: "star.fill")
                StatBadge(value: "4.8", label: "Rating", icon: "heart.fill")
            }
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 10)

            // Testimonial
            VStack(spacing: 8) {
                Text("\"Tiny Wins helped us notice the good moments we were missing. Now bedtime feels like a celebration, not a battle.\"")
                    .font(.system(size: 14, weight: .medium))
                    .italic()
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Text("— Sarah, mom of 2")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 10)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.3)) {
                hasAppeared = true
            }
        }
    }
}

private struct StatBadge: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.purple)
                Text(value)
                    .font(.system(size: 18, weight: .bold))
            }
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Pricing Card

private struct PricingCard: View {
    let product: Product
    let isSelected: Bool
    let isPopular: Bool
    let savings: Int?
    let onSelect: () -> Void

    private var isYearly: Bool {
        product.id == SubscriptionManager.yearlyProductId
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                // Popular badge - only show if yearly and has actual savings
                if isPopular && isYearly {
                    Text("ANNUAL PLAN")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isYearly ? "Yearly" : "Monthly")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)

                        // Only show savings if calculated from actual prices
                        if let savings = savings, savings > 0 {
                            Text("Save \(savings)%")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.green)
                        }

                        if isYearly {
                            Text("\(product.localizedPricePerMonth)/month")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(product.displayPrice)
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.primary)
                        Text(isYearly ? "/year" : "/month")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
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
                RoundedRectangle(cornerRadius: isPopular && isYearly ? 0 : 20)
                    .fill(isSelected ? Color.purple.opacity(0.1) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: isPopular && isYearly ? 0 : 20)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isYearly ? "Yearly" : "Monthly") plan, \(product.displayPrice). \(isSelected ? "Selected" : "Not selected")")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint("Double tap to select this plan")
    }
}

// MARK: - Demo Pricing Card (for developer testing)

private struct DemoPricingCard: View {
    let plan: DemoPlan
    let isSelected: Bool
    let isPopular: Bool
    let onSelect: () -> Void

    private var isYearly: Bool {
        plan == .yearly
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                // Popular badge for yearly
                if isPopular && isYearly {
                    Text("ANNUAL PLAN")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isYearly ? "Yearly" : "Monthly")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)

                        // Show savings for yearly
                        if let savings = plan.savings, savings > 0 {
                            Text("Save \(savings)%")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.green)
                        }

                        if isYearly {
                            Text("\(plan.monthlyEquivalent)/month")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(plan.displayPrice)
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.primary)
                        Text(isYearly ? "/year" : "/month")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
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
                RoundedRectangle(cornerRadius: isPopular && isYearly ? 0 : 20)
                    .fill(isSelected ? Color.purple.opacity(0.1) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: isPopular && isYearly ? 0 : 20)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isYearly ? "Yearly" : "Monthly") plan, \(plan.displayPrice). \(isSelected ? "Selected" : "Not selected")")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint("Double tap to select this plan")
    }
}

// MARK: - Comparison Row

private struct ComparisonRow: View {
    let feature: String
    var freeText: String? = nil
    var plusText: String? = nil
    var freeCheck: Bool? = nil
    var plusCheck: Bool? = nil

    init(feature: String, free: String, plus: String) {
        self.feature = feature
        self.freeText = free
        self.plusText = plus
    }

    init(feature: String, free: Bool, plus: Bool) {
        self.feature = feature
        self.freeCheck = free
        self.plusCheck = plus
    }

    var body: some View {
        HStack {
            Text(feature)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Free column
            Group {
                if let text = freeText {
                    Text(text)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else if let check = freeCheck {
                    Image(systemName: check ? "checkmark.circle.fill" : "minus.circle")
                        .foregroundColor(check ? .green : .secondary)
                        .font(.system(size: 14))
                }
            }
            .frame(width: 60)

            // Plus column
            Group {
                if let text = plusText {
                    Text(text)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.purple)
                } else if let check = plusCheck {
                    Image(systemName: check ? "checkmark.circle.fill" : "minus.circle")
                        .foregroundColor(check ? .purple : .secondary)
                        .font(.system(size: 14))
                }
            }
            .frame(width: 60)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview

#Preview {
    PlusPaywallView()
}
