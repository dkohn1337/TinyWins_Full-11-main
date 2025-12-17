import SwiftUI

/// Family Plan view showing collaborative goals and practices in supportive language
/// Replaces the contract-like agreement with a softer, team-based approach
struct FamilyPlanView: View {
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @EnvironmentObject private var rewardsStore: RewardsStore
    @EnvironmentObject private var agreementsStore: AgreementsStore
    @Environment(\.dismiss) private var dismiss

    let child: Child

    @State private var showingShareSheet = false
    @State private var planImage: UIImage?
    @State private var showAllBehaviors = false
    @State private var showingTeamTalkExpanded = false
    @State private var highlightCheckIn = false
    @Namespace private var scrollNamespace

    // Get the latest child data from childrenStore
    private var currentChild: Child {
        childrenStore.child(id: child.id) ?? child
    }

    // Single source of truth for plan status
    private var coverageStatus: AgreementCoverageStatus {
        agreementsStore.agreementCoverageStatus(
            forChild: currentChild.id,
            agreementVersions: rewardsStore.agreementVersions,
            rewards: rewardsStore.rewards
        )
    }

    private var currentAgreement: AgreementVersion? {
        agreementsStore.currentAgreement(forChild: currentChild.id, agreementVersions: rewardsStore.agreementVersions)
    }

    private var activeRewards: [Reward] {
        rewardsStore.rewards(forChild: currentChild.id)
            .filter { !$0.isRedeemed && !$0.isExpired }
            .sorted { $0.priority < $1.priority }
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        // Tappable header with status
                        headerSection(proxy: proxy)

                        // What we're practicing section
                        practicingSection
                            .id("practicing")

                        // Our goals section
                        goalsSection(proxy: proxy)
                            .id("goals")

                        // How we'll support section
                        supportSection
                            .id("support")

                        // Check-in section (replaces signatures)
                        checkInSection(proxy: proxy)
                            .id("checkin")

                        // Reminder at bottom
                        reminderNote
                    }
                    .padding()
                    .padding(.bottom, 40) // Extra bottom spacing for home indicator and scrolling comfort
                }
                .background(
                    AppColors.childGradient(for: currentChild.colorTag.color)
                        .ignoresSafeArea()
                )
            }
            .navigationTitle("Our Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: sharePlan) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let image = planImage {
                    ShareSheet(items: [image])
                }
            }
        }
    }

    // MARK: - Header Section

    private func headerSection(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 12) {
            // Child avatar and name
            HStack(spacing: 12) {
                Circle()
                    .fill(currentChild.colorTag.color.opacity(0.2))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(String(currentChild.name.prefix(1)).uppercased())
                            .font(.title2.bold())
                            .foregroundColor(currentChild.colorTag.color)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Our Plan for")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(currentChild.name)
                        .font(.title3.bold())
                }

                Spacer()

                // Status pill
                statusPill(proxy: proxy)
            }

            // Subtitle
            Text("What we're working on together as a team")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(AppStyles.cardCornerRadius)
        .shadow(color: AppStyles.cardShadow, radius: AppStyles.cardShadowRadius, y: 2)
    }

    private func statusPill(proxy: ScrollViewProxy) -> some View {
        let (text, color) = statusPillContent

        return Button(action: {
            withAnimation(.spring()) {
                highlightCheckIn = true
            }
            withAnimation {
                proxy.scrollTo("checkin", anchor: .center)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    highlightCheckIn = false
                }
            }
        }) {
            Text(text)
                .font(.caption2.weight(.semibold))
                .foregroundColor(color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(color.opacity(0.15))
                .cornerRadius(12)
        }
    }

    private var statusPillContent: (String, Color) {
        switch coverageStatus {
        case .neverSigned:
            return ("Not checked in yet", Color.orange)
        case .signedCurrent:
            return ("On the same page", Color.green)
        case .signedOutOfDate:
            return ("Time to refresh", Color.orange)
        }
    }

    // MARK: - What We're Practicing Section

    private var practicingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                StyledIcon(systemName: "star.circle.fill", color: currentChild.colorTag.color, size: 16, backgroundSize: 32, isCircle: true)
                Text("\(currentChild.name) is practicing")
                    .font(.headline)
            }

            Text("These are the behaviors we're noticing and celebrating together")
                .font(.caption)
                .foregroundColor(.secondary)

            // Positive behaviors
            let positiveBehaviors = behaviorsStore.behaviorTypes.filter { $0.category == .positive }
            let displayBehaviors = showAllBehaviors ? positiveBehaviors : Array(positiveBehaviors.prefix(5))

            VStack(spacing: 8) {
                ForEach(displayBehaviors) { behavior in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(currentChild.colorTag.color)
                            .font(.body)

                        Text(behavior.name)
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }

            // Show more/less button
            if positiveBehaviors.count > 5 {
                Button(action: {
                    withAnimation(.spring()) {
                        showAllBehaviors.toggle()
                    }
                }) {
                    HStack {
                        Text(showAllBehaviors ? "Show Less" : "Show More (\(positiveBehaviors.count - 5) more)")
                            .font(.caption.weight(.medium))
                            .foregroundColor(currentChild.colorTag.color)
                        Image(systemName: showAllBehaviors ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(currentChild.colorTag.color)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(AppStyles.cardCornerRadius)
        .shadow(color: AppStyles.cardShadow, radius: AppStyles.cardShadowRadius, y: 2)
    }

    // MARK: - Goals Section

    private func goalsSection(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                StyledIcon(systemName: "target", color: .purple, size: 16, backgroundSize: 32, isCircle: true)
                Text("What we're working toward")
                    .font(.headline)
            }

            if activeRewards.isEmpty {
                Text("No goals set up yet. Add one to get started!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(activeRewards) { reward in
                        goalRow(reward: reward, proxy: proxy)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(AppStyles.cardCornerRadius)
        .shadow(color: AppStyles.cardShadow, radius: AppStyles.cardShadowRadius, y: 2)
    }

    private func goalRow(reward: Reward, proxy: ScrollViewProxy) -> some View {
        let isCovered = agreementsStore.isRewardCoveredByAgreement(
            rewardId: reward.id,
            childId: currentChild.id,
            agreementVersions: rewardsStore.agreementVersions
        )
        let needsPlanUpdate = !isCovered && coverageStatus != .neverSigned

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(reward.name)
                    .font(.subheadline.weight(.medium))

                Spacer()

                if needsPlanUpdate {
                    Text("New")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(4)
                }
            }

            // Progress bar
            let progress = reward.progress(from: behaviorsStore.behaviorEvents, isPrimaryReward: activeRewards.first?.id == reward.id)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(currentChild.colorTag.color)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(reward.pointsEarnedInWindow(from: behaviorsStore.behaviorEvents, isPrimaryReward: activeRewards.first?.id == reward.id)) of \(reward.targetPoints) stars")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if needsPlanUpdate {
                    Button(action: {
                        withAnimation {
                            proxy.scrollTo("checkin", anchor: .top)
                        }
                    }) {
                        Text("Check in together")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(needsPlanUpdate ? Color.orange.opacity(0.05) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(needsPlanUpdate ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    // MARK: - Support Section

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                StyledIcon(systemName: "heart.fill", color: .pink, size: 16, backgroundSize: 32, isCircle: true)
                Text("How grown-ups will help")
                    .font(.headline)
            }

            Text("Ways we support \(currentChild.name) on this journey")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                supportPoint(icon: "checkmark.circle", text: "Notice and celebrate small wins every day")
                supportPoint(icon: "clock", text: "Give reminders with patience, not pressure")
                supportPoint(icon: "hand.raised.fill", text: "Remember that some days are harder than others")
                supportPoint(icon: "message", text: "Talk about feelings, not just behavior")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(AppStyles.cardCornerRadius)
        .shadow(color: AppStyles.cardShadow, radius: AppStyles.cardShadowRadius, y: 2)
    }

    private func supportPoint(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.pink)
                .font(.body)
                .frame(width: 20)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }

    // MARK: - Team Talk Section (kid-friendly check-in)

    private func checkInSection(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with friendly icon
            HStack {
                Text("🤝")
                    .font(.title2)
                Text("Team Talk")
                    .font(.headline)

                Spacer()

                // Status indicator (simple, no dates)
                if coverageStatus == .signedCurrent {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(relativeTimeText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Simple status message
            Text(teamTalkMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Expandable content (replaces popup)
            if showingTeamTalkExpanded || coverageStatus != .signedCurrent {
                teamTalkContent
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }

            // Action button
            teamTalkButton
        }
        .padding()
        .background(
            Color(.systemBackground)
                .overlay(
                    highlightCheckIn ?
                    Color.yellow.opacity(0.15) : Color.clear
                )
        )
        .cornerRadius(AppStyles.cardCornerRadius)
        .shadow(color: AppStyles.cardShadow, radius: AppStyles.cardShadowRadius, y: 2)
        .animation(.spring(response: 0.3), value: showingTeamTalkExpanded)
        .animation(.easeInOut(duration: 0.3), value: highlightCheckIn)
    }

    private var relativeTimeText: String {
        guard let signedDate = currentChild.childSignature.signedAt else {
            return ""
        }

        let daysSince = Calendar.current.dateComponents([.day], from: signedDate, to: Date()).day ?? 0

        if daysSince == 0 {
            return "Today"
        } else if daysSince == 1 {
            return "Yesterday"
        } else if daysSince < 7 {
            return "\(daysSince) days ago"
        } else if daysSince < 14 {
            return "Last week"
        } else {
            return "A while ago"
        }
    }

    private var teamTalkMessage: String {
        switch coverageStatus {
        case .neverSigned:
            return "Have a quick chat about what you're working on together!"
        case .signedCurrent:
            return "You and \(currentChild.name) are on the same team! 💪"
        case .signedOutOfDate:
            return "Goals changed! Time for a quick team chat."
        }
    }

    private var teamTalkContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Talk about:")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                teamTalkPoint(emoji: "⭐", text: "What's going well")
                teamTalkPoint(emoji: "🎯", text: "What we're working toward")
                teamTalkPoint(emoji: "💙", text: "How we'll help each other")
            }
        }
        .padding()
        .background(currentChild.colorTag.color.opacity(0.08))
        .cornerRadius(12)
    }

    private func teamTalkPoint(emoji: String, text: String) -> some View {
        HStack(spacing: 10) {
            Text(emoji)
                .font(.body)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }

    @ViewBuilder
    private var teamTalkButton: some View {
        switch coverageStatus {
        case .neverSigned:
            Button(action: {
                markPlanAsReviewed()
            }) {
                HStack(spacing: 8) {
                    Text("We Talked!")
                    Text("🎉")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(currentChild.colorTag.color)
                .cornerRadius(AppStyles.buttonCornerRadius)
            }

        case .signedCurrent:
            Button(action: {
                withAnimation {
                    showingTeamTalkExpanded.toggle()
                }
            }) {
                HStack {
                    Text(showingTeamTalkExpanded ? "Hide details" : "Talk again")
                        .font(.caption.weight(.medium))
                    Image(systemName: showingTeamTalkExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(currentChild.colorTag.color)
            }

        case .signedOutOfDate:
            Button(action: {
                markPlanAsReviewed()
            }) {
                HStack(spacing: 8) {
                    Text("We're Back on Track!")
                    Text("🙌")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.orange)
                .cornerRadius(AppStyles.buttonCornerRadius)
            }
        }
    }

    // MARK: - Reminder Note

    private var reminderNote: some View {
        VStack(spacing: 8) {
            Text("Remember")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            Text("This is a guide, not a test. Some days will be easier than others, and that's okay.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }

    // MARK: - Helper Functions

    private func markPlanAsReviewed() {
        // Create simple timestamp marker (reuses existing signature structure but without actual signature drawing)
        let markerData = "checked_in".data(using: .utf8) ?? Data() // Simple marker instead of PNG signature

        // Get active behavior type IDs for the agreement
        let activeBehaviorTypeIds = behaviorsStore.behaviorTypes
            .filter { $0.isActive }
            .map { $0.id }

        // Sign using rewardsStore which properly creates/updates AgreementVersion objects
        // This updates the agreement status that the UI reads from
        rewardsStore.signAgreement(
            childId: currentChild.id,
            signatureType: .child,
            signatureData: markerData,
            activeBehaviorTypeIds: activeBehaviorTypeIds
        )
        rewardsStore.signAgreement(
            childId: currentChild.id,
            signatureType: .parent,
            signatureData: markerData,
            activeBehaviorTypeIds: activeBehaviorTypeIds
        )
    }

    private func sharePlan() {
        // Render plan as image for sharing
        // Implementation similar to existing shareAgreement but for new layout
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 800))

        planImage = renderer.image { context in
            // Simplified rendering - would need full implementation
            let backgroundColor = UIColor.systemBackground
            backgroundColor.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 600, height: 800))

            // Add title
            let title = "Our Plan for \(currentChild.name)" as NSString
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.label
            ]
            title.draw(at: CGPoint(x: 20, y: 20), withAttributes: titleAttributes)
        }

        showingShareSheet = true
    }
}

// MARK: - Preview

#Preview {
    let repository = Repository()
    let child = Child(name: "Emma", age: 7, colorTag: .purple)

    return FamilyPlanView(child: child)
        .environmentObject(repository)
        .environmentObject(ChildrenStore(repository: repository))
        .environmentObject(BehaviorsStore(repository: repository))
        .environmentObject(RewardsStore(repository: repository))
        .environmentObject(AgreementsStore(repository: repository))
}
