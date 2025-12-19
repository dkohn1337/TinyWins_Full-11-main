import SwiftUI

/// Personalized reflection prompts based on today's events (Plus feature)
struct PersonalizedPromptView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @EnvironmentObject private var childrenStore: ChildrenStore

    private var prompt: ReflectionPrompt {
        generatePrompt()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("Reflection Prompt")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.purple)

                Spacer()

                // Plus badge
                Text("PLUS")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(4)
            }

            Text(prompt.text)
                .font(.subheadline)
                .foregroundColor(theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let context = prompt.context {
                Text(context)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.08), Color.pink.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Prompt Generation

    private func generatePrompt() -> ReflectionPrompt {
        let todayEvents = behaviorsStore.todayEvents
        let children = childrenStore.children

        // Count positives and challenges
        let positiveEvents = todayEvents.filter { $0.pointsApplied > 0 }
        let challengeEvents = todayEvents.filter { $0.pointsApplied < 0 }

        // Analyze by child
        let eventsByChild = Dictionary(grouping: todayEvents) { $0.childId }

        // Priority 1: If there were challenges today
        if !challengeEvents.isEmpty {
            if let childId = challengeEvents.first?.childId,
               let child = children.first(where: { $0.id == childId }) {
                return ReflectionPrompt(
                    text: "You logged a challenge with \(child.name) today. What helped you navigate that moment?",
                    context: "Reflecting on challenges helps us grow",
                    type: .challenge
                )
            }
            return ReflectionPrompt(
                text: "Today had some challenges. What helped you stay grounded?",
                context: "Challenges are part of the journey",
                type: .challenge
            )
        }

        // Priority 2: High positive day
        if positiveEvents.count >= 5 {
            // Find child with most wins
            let childWinCounts = eventsByChild.mapValues { events in
                events.filter { $0.pointsApplied > 0 }.count
            }
            if let topChildId = childWinCounts.max(by: { $0.value < $1.value })?.key,
               let child = children.first(where: { $0.id == topChildId }),
               let winCount = childWinCounts[topChildId] {
                return ReflectionPrompt(
                    text: "\(child.name) had \(winCount) wins today! What made it such a great day?",
                    context: "Celebrating success reinforces positive patterns",
                    type: .celebration
                )
            }
            return ReflectionPrompt(
                text: "What a day! \(positiveEvents.count) positive moments logged. What made today special?",
                context: "Great days are worth remembering",
                type: .celebration
            )
        }

        // Priority 3: Moderate activity
        if !positiveEvents.isEmpty {
            if let mostRecentEvent = positiveEvents.sorted(by: { $0.timestamp > $1.timestamp }).first,
               let child = children.first(where: { $0.id == mostRecentEvent.childId }),
               let behaviorType = behaviorsStore.behaviorType(id: mostRecentEvent.behaviorTypeId) {
                return ReflectionPrompt(
                    text: "You noticed \(child.name) doing \"\(behaviorType.name)\" today. What did that moment feel like?",
                    context: "Noticing the details helps us appreciate more",
                    type: .moment
                )
            }
            return ReflectionPrompt(
                text: "You logged \(positiveEvents.count) positive moment\(positiveEvents.count == 1 ? "" : "s") today. Which one stands out?",
                context: nil,
                type: .moment
            )
        }

        // Priority 4: Quiet day
        return ReflectionPrompt(
            text: "It's been a quiet day. What small moment are you grateful for?",
            context: "Even quiet days have hidden wins",
            type: .gratitude
        )
    }
}

// MARK: - Reflection Prompt Model

struct ReflectionPrompt {
    let text: String
    let context: String?
    let type: PromptType

    enum PromptType {
        case challenge
        case celebration
        case moment
        case gratitude
    }
}

// MARK: - Preview

#Preview {
    let repository = Repository.preview
    PersonalizedPromptView()
        .environmentObject(BehaviorsStore(repository: repository))
        .environmentObject(ChildrenStore(repository: repository))
        .padding()
}
