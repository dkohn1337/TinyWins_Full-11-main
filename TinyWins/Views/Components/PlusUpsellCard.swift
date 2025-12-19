import SwiftUI

/// A contextual upsell card for TinyWins Plus features
struct PlusUpsellCard: View {
    let context: PlusUpsellContext
    let onTapSeeMore: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: context.icon)
                    .font(.title2)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(context.title)
                            .font(.headline)
                        
                        PlusBadge()
                    }
                    
                    Text(context.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Button(action: onTapSeeMore) {
                Text("See TinyWins Plus")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.purple)
                    .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color.purple.opacity(0.08))
        .cornerRadius(16)
    }
}

/// A compact inline upsell for premium-locked items
struct PlusLockedOverlay: View {
    @Environment(\.theme) private var theme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.title3)
                    .foregroundColor(.purple)

                PlusBadge()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.surface1.opacity(0.95))
        }
        .buttonStyle(.plain)
    }
}

/// The TinyWins Plus badge
struct PlusBadge: View {
    var small: Bool = false
    
    var body: some View {
        Text("Plus")
            .font(small ? .caption2 : .caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, small ? 5 : 6)
            .padding(.vertical, small ? 2 : 3)
            .background(
                LinearGradient(
                    colors: [.purple, .purple.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(small ? 4 : 5)
    }
}

/// A compact lock indicator for premium items in grids/lists
struct PlusLockBadge: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "lock.fill")
                .font(.caption2)
            PlusBadge(small: true)
        }
    }
}

// MARK: - Preview

#Preview("Upsell Card") {
    VStack(spacing: 20) {
        PlusUpsellCard(context: .addChild) {}
        PlusUpsellCard(context: .longTermInsights) {}
        PlusUpsellCard(context: .iCloudBackup) {}
    }
    .padding()
}

#Preview("Badges") {
    VStack(spacing: 20) {
        PlusBadge()
        PlusBadge(small: true)
        PlusLockBadge()
    }
    .padding()
}
