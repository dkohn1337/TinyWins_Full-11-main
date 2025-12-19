import SwiftUI

// MARK: - Pricing Components
// Components for paywall and pricing displays

/// Feature row for paywall with value indicator
struct PremiumFeatureRowView: View {
    @Environment(\.theme) private var theme
    let icon: String
    let title: String
    let description: String
    let value: String?
    let gradient: [Color]

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: gradient[0].opacity(0.4), radius: 12)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Value
            if let value = value {
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
                    .strikethrough()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface1)
        )
    }
}

/// Selectable pricing plan card
struct PricingPlanCardView: View {
    @Environment(\.theme) private var theme
    let title: String
    let price: String
    let billingCycle: String
    let savings: String?
    let isSelected: Bool
    let isPopular: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Popular badge
                if isPopular {
                    Text("MOST POPULAR")
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
                        .cornerRadius(8)
                        .offset(y: -28)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(theme.textPrimary)

                        if let savings = savings {
                            Text(savings)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.green)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(price)
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(theme.textPrimary)
                        Text(billingCycle)
                            .font(.system(size: 14))
                            .foregroundColor(theme.textSecondary)
                    }
                }

                if isSelected {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Selected")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.purple.opacity(0.1) : theme.surface1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                isSelected ?
                                    LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                    LinearGradient(colors: [theme.borderStrong], startPoint: .top, endPoint: .bottom),
                                lineWidth: isSelected ? 3 : 1
                            )
                    )
            )
            .shadow(color: isSelected ? .purple.opacity(0.2) : .clear, radius: 20, y: 10)
        }
        .buttonStyle(.plain)
    }
}
