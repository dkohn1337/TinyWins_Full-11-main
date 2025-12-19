import SwiftUI

/// Evening reflection prompt card for Today tab
/// Shows contextually in evening hours when user hasn't reflected today
struct EveningReflectionCard: View {
    @EnvironmentObject private var repository: Repository
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @Environment(\.theme) private var theme

    let onTap: () -> Void

    // MARK: - Computed Properties

    private var reflectionStreak: Int {
        repository.appData.calculateReflectionStreak()
    }

    private var hasReflectedToday: Bool {
        let todayNotes = repository.getParentNotes(forDay: Date())
        return todayNotes.contains { $0.noteType == .parentWin || $0.noteType == .reflection }
    }

    private var todayMomentCount: Int {
        behaviorsStore.todayEvents.count
    }

    private var messageText: String {
        if todayMomentCount == 0 {
            return "Take a moment to reflect on your day."
        } else if todayMomentCount == 1 {
            return "You logged 1 moment today. How did it go?"
        } else {
            return "You logged \(todayMomentCount) moments today. Celebrate your wins."
        }
    }

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Moon icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.2), .indigo.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .indigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text("End Your Day Mindfully")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(theme.textPrimary)

                    Text(messageText)
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(2)

                    // Reflection count badge (no streak framing)
                    if reflectionStreak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            Text("\(reflectionStreak) day\(reflectionStreak == 1 ? "" : "s") of reflection")
                                .font(.caption2.weight(.medium))
                                .foregroundColor(.orange)
                        }
                        .padding(.top, 2)
                    }
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [.purple.opacity(0.3), .indigo.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: .purple.opacity(0.1), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Visibility Helper

extension EveningReflectionCard {
    /// Determines if the evening reflection card should be shown
    /// Shows between 6pm and midnight, only if user hasn't reflected today
    static func shouldShow(repository: Repository) -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        let isEvening = hour >= 18 // 6pm or later

        guard isEvening else { return false }

        // Check if user has already reflected today
        let todayNotes = repository.getParentNotes(forDay: Date())
        let hasReflectedToday = todayNotes.contains {
            $0.noteType == .parentWin || $0.noteType == .reflection
        }

        return !hasReflectedToday
    }
}

// MARK: - Preview

#Preview("Evening Card") {
    VStack {
        EveningReflectionCard(onTap: {})
            .environmentObject(Repository.preview)
            .environmentObject(BehaviorsStore(repository: Repository.preview))
    }
    .padding()
    .background(Theme().bg1)
    .withTheme(Theme())
}

#Preview("With Streak") {
    VStack {
        EveningReflectionCard(onTap: {})
            .environmentObject(Repository.preview)
            .environmentObject(BehaviorsStore(repository: Repository.preview))
    }
    .padding()
    .background(Theme().bg1)
    .withTheme(Theme())
}
