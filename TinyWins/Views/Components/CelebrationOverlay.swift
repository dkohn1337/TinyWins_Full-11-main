import SwiftUI

/// Unified celebration overlay that displays any celebration type from CelebrationManager.
/// Uses consistent styling with darkened background, centered card, X button, and primary action.
struct CelebrationOverlay: View {
    @EnvironmentObject private var celebrationManager: CelebrationManager
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var repository: Repository
    let celebration: CelebrationManager.CelebrationType
    let onDismiss: () -> Void

    @State private var showingShareSheet = false
    @State private var shareText = ""

    var body: some View {
        // Use new full-screen celebration views based on type
        switch celebration {
        case .goalReached(let childId, let childName, _, let rewardName, _):
            let childColor = getChildColor(childId: childId)
            GoalCelebrationView(
                childName: childName,
                childColor: childColor,
                rewardName: rewardName,
                onDismiss: onDismiss,
                onShare: {
                    shareGoalAchievement(childName: childName, rewardName: rewardName)
                }
            )
            .sheet(isPresented: $showingShareSheet) {
                ActivityShareSheet(items: [shareText])
            }

        case .goldStarDay(_, _, let count):
            GoldStarDayCelebrationView(
                momentCount: count,
                onDismiss: onDismiss
            )

        case .milestoneReached(let childId, let childName, _, let rewardName, let milestone, let target, _):
            let childColor = getChildColor(childId: childId)
            MilestoneCelebrationView(
                childName: childName,
                childColor: childColor,
                milestoneName: "\(Int((Double(milestone) / Double(target)) * 100))% to \(rewardName)",
                milestoneIcon: "flag.fill",
                onDismiss: onDismiss
            )

        case .patternFound(_, _, _, _, _, let insight):
            MilestoneCelebrationView(
                childName: "",
                childColor: insight.color,
                milestoneName: insight.message,
                milestoneIcon: insight.icon,
                onDismiss: onDismiss
            )
        }
    }

    // Helper to get child color from child ID
    private func getChildColor(childId: UUID) -> Color {
        guard let child = childrenStore.children.first(where: { $0.id == childId }) else {
            return .blue // Default fallback
        }
        return child.colorTag.color
    }

    // MARK: - Share Functionality

    private func shareGoalAchievement(childName: String, rewardName: String) {
        let familyName = repository.appData.family.name
        shareText = """
        🎉 Goal Reached!

        \(childName) from \(familyName) just earned "\(rewardName)"!

        We're celebrating the small wins together with Tiny Wins.
        """
        showingShareSheet = true
    }

    // MARK: - Celebration Icon
    
    @ViewBuilder
    private var celebrationIcon: some View {
        switch celebration {
        case .goalReached(_, _, _, _, let icon):
            // Green trophy icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 110, height: 110)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green, Color(red: 0.2, green: 0.7, blue: 0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .green.opacity(0.4), radius: 12)
                
                Image(systemName: icon ?? "trophy.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            
        case .goldStarDay:
            // Yellow star icon
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.15))
                    .frame(width: 110, height: 110)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .yellow.opacity(0.5), radius: 15)
                
                Image(systemName: "star.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
        case .milestoneReached(_, _, _, _, let milestone, let target, _):
            // Blue flag icon with percentage
            let percent = Int((Double(milestone) / Double(target)) * 100)
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 110, height: 110)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .blue.opacity(0.4), radius: 12)
                
                VStack(spacing: 0) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 24))
                    Text("\(percent)%")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
            }
            
        case .patternFound(_, _, _, _, _, let insight):
            // Pattern icon with custom color
            ZStack {
                Circle()
                    .fill(insight.color.opacity(0.15))
                    .frame(width: 110, height: 110)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [insight.color, insight.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: insight.color.opacity(0.4), radius: 12)
                
                Image(systemName: insight.icon)
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Celebration Content
    
    @ViewBuilder
    private var celebrationContent: some View {
        switch celebration {
        case .goalReached(_, let childName, _, let rewardName, _):
            VStack(spacing: 12) {
                Text("Goal Reached!")
                    .font(.title2.bold())

                HStack(spacing: 8) {
                    Image(systemName: "gift.fill")
                        .foregroundColor(.green)
                    Text(rewardName)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.green)
                }

                Divider()
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("You both worked toward this goal.")
                        .font(.body.weight(.medium))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Try saying:")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)

                    Text("\"\(childName), I noticed how hard you tried. I'm proud of your effort.\"")
                        .font(.subheadline)
                        .italic()
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 4)
            }
            
        case .goldStarDay(_, _, let count):
            VStack(spacing: 8) {
                Text("Gold Star Day!")
                    .font(.title.weight(.bold))
                
                Text("You noticed \(count) positive moments today.\nThat attention matters more than you know.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
        case .milestoneReached(_, let childName, _, let rewardName, let milestone, let target, let message):
            let percent = Int((Double(milestone) / Double(target)) * 100)
            VStack(spacing: 8) {
                Text("Making Progress!")
                    .font(.title2.weight(.bold))
                
                Text("\(childName) is \(percent)% of the way to")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text(rewardName)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.blue)
                
                Text(message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
            
        case .patternFound(_, _, _, _, _, let insight):
            VStack(spacing: 8) {
                Text(insight.title)
                    .font(.title2.weight(.bold))
                
                Text(insight.message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let suggestion = insight.suggestion {
                    Text(suggestion)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
        }
    }
    
    // MARK: - Primary Button
    
    @ViewBuilder
    private var primaryButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                onDismiss()
            }
        }) {
            Text(buttonText)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(buttonGradient)
                .cornerRadius(14)
        }
        .padding(.top, 4)
        .accessibilityLabel(buttonText)
        .accessibilityHint("Double tap to dismiss celebration")
        .accessibilityAddTraits(.isButton)
    }
    
    private var buttonText: String {
        switch celebration {
        case .goalReached: return "Go Celebrate Together"
        case .goldStarDay: return "Keep It Up!"
        case .milestoneReached: return "Great Progress!"
        case .patternFound: return "Got It!"
        }
    }
    
    private var buttonGradient: LinearGradient {
        switch celebration {
        case .goalReached:
            return LinearGradient(
                colors: [.green, Color(red: 0.2, green: 0.7, blue: 0.4)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .goldStarDay:
            return LinearGradient(
                colors: [.purple, .pink],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .milestoneReached:
            return LinearGradient(
                colors: [.blue, .cyan],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .patternFound(_, _, _, _, _, let insight):
            return LinearGradient(
                colors: [insight.color, insight.color.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

// MARK: - Secondary Celebration Banner

/// Lightweight banner for secondary celebrations (shown after primary modal dismisses)
struct SecondaryCelebrationBanner: View {
    let celebration: CelebrationManager.SecondaryCelebration
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(celebration.color.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: celebration.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(celebration.color)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(celebration.type)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(celebration.color)
                
                Text(celebration.message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Dismiss button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("Dismiss")
            .accessibilityHint("Double tap to dismiss notification")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        )
        .padding(.horizontal, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(celebration.type): \(celebration.message)")
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        
        CelebrationOverlay(
            celebration: .goldStarDay(childId: UUID(), childName: "Ellie", momentCount: 5),
            onDismiss: {}
        )
        .environmentObject(CelebrationManager())
    }
}

// MARK: - Activity Share Sheet

/// Simple wrapper for UIActivityViewController
struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
