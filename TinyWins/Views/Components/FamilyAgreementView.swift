import SwiftUI

/// Family Plan view showing goals in kid-friendly language with celebratory participation drawings
/// Note: This is NOT a legal contract - it's a fun family activity to discuss goals together
struct FamilyAgreementView: View {
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @EnvironmentObject private var rewardsStore: RewardsStore
    @EnvironmentObject private var agreementsStore: AgreementsStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    let child: Child
    
    @State private var showingShareSheet = false
    @State private var agreementImage: UIImage?
    @State private var showingChildSignature = false
    @State private var showingParentSignature = false
    @State private var showAllBehaviors = false
    @State private var showingSignedToast = false
    @State private var highlightSignatures = false
    @Namespace private var scrollNamespace
    
    // Get the latest child data from childrenStore
    private var currentChild: Child {
        childrenStore.child(id: child.id) ?? child
    }

    // Single source of truth for agreement status
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
                        
                        // I Earn Stars By section
                        earnsStarsSection
                            .id("behaviors")
                        
                        // My Goals section
                        myGoalsSection(proxy: proxy)
                            .id("goals")
                        
                        // Signature section
                        signatureSection(proxy: proxy)
                            .id("signatures")
                    }
                    .padding()
                }
                .background(
                    AppColors.childGradient(for: currentChild.colorTag.color)
                        .ignoresSafeArea()
                )
            }
            .navigationTitle("Family Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: shareAgreement) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let image = agreementImage {
                    ShareSheet(items: [image])
                }
            }
            .sheet(isPresented: $showingChildSignature) {
                ParticipationSheet(
                    type: .child,
                    childName: currentChild.name,
                    onComplete: { drawingData in
                        childrenStore.signAgreement(childId: currentChild.id, signatureType: .child, signatureData: drawingData)
                        checkForCompletedAgreement()
                    }
                )
            }
            .sheet(isPresented: $showingParentSignature) {
                ParticipationSheet(
                    type: .parent,
                    childName: currentChild.name,
                    onComplete: { drawingData in
                        childrenStore.signAgreement(childId: currentChild.id, signatureType: .parent, signatureData: drawingData)
                        checkForCompletedAgreement()
                    }
                )
            }
            .toast(isShowing: $showingSignedToast, message: "You updated \(currentChild.name)'s family plan. Talking about goals together helps kids feel included!", icon: "checkmark.circle.fill", category: .positive)
        }
    }
    
    private func checkForCompletedAgreement() {
        // Check if agreement is now fully signed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if coverageStatus == .signedCurrent {
                showingSignedToast = true
            }
        }
    }
    
    // MARK: - Header Section (Tappable)
    
    private func headerSection(proxy: ScrollViewProxy) -> some View {
        Button(action: {
            // Scroll to signatures with highlight
            withAnimation(.easeInOut(duration: 0.5)) {
                proxy.scrollTo("signatures", anchor: .top)
            }
            // Brief highlight effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    highlightSignatures = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        highlightSignatures = false
                    }
                }
            }
        }) {
            VStack(spacing: 16) {
                // Child avatar
                ZStack {
                    Circle()
                        .fill(currentChild.colorTag.color)
                        .frame(width: 80, height: 80)
                        .shadow(color: currentChild.colorTag.color.opacity(0.4), radius: 10)
                    
                    Text(currentChild.initials)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                // Title
                Text("\(currentChild.name)'s Family Plan")
                    .font(AppStyles.childFriendlyFont)
                    .foregroundColor(theme.textPrimary)
                
                // Last signed date (if applicable)
                if let signedDate = lastSignedDate {
                    Text(signedDateText(signedDate))
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                
                // Status pill
                statusPill
                
                // Subtext
                Text(coverageStatus.subtext)
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(theme.surface1)
            .cornerRadius(AppStyles.cardCornerRadius)
            .shadow(color: AppStyles.cardShadow, radius: AppStyles.cardShadowRadius, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    private var lastSignedDate: Date? {
        currentAgreement?.signedDate
    }
    
    private func signedDateText(_ date: Date) -> String {
        switch coverageStatus {
        case .neverSigned:
            return ""
        case .signedCurrent:
            return "Signed on \(formattedDate(date))"
        case .signedOutOfDate:
            return "Last signed on \(formattedDate(date))"
        }
    }
    
    private var statusPill: some View {
        HStack(spacing: 6) {
            Image(systemName: statusIcon)
                .font(.caption.weight(.semibold))
            Text(coverageStatus.statusPillText)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(coverageStatus.statusPillColor)
        .foregroundColor(.white)
        .cornerRadius(20)
    }
    
    private var statusIcon: String {
        switch coverageStatus {
        case .neverSigned:
            return "pencil.circle"
        case .signedCurrent:
            return "checkmark.circle.fill"
        case .signedOutOfDate:
            return "exclamationmark.circle"
        }
    }
    
    // MARK: - Earns Stars Section

    private var earnsStarsSection: some View {
        let positiveBehaviors = behaviorsStore.suggestedBehaviors(forChild: currentChild)
            .filter { $0.category != .negative && $0.isActive }
            .sorted { $0.defaultPoints > $1.defaultPoints }
        
        let displayedBehaviors = showAllBehaviors ? positiveBehaviors : Array(positiveBehaviors.prefix(3))
        let hasMore = positiveBehaviors.count > 3
        
        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    StyledIcon(systemName: "star.fill", color: theme.textSecondary, size: 16, backgroundSize: 32, isCircle: true)
                    Text("I Earn Stars By...")
                        .font(.headline)
                }

                Text("These are the moments we're noticing together")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                    .padding(.leading, 40)
            }
            
            if positiveBehaviors.isEmpty {
                emptyBehaviorsState
            } else {
                ForEach(displayedBehaviors, id: \.id) { behavior in
                    behaviorRow(behavior: behavior, isPositive: true)
                    
                    if behavior.id != displayedBehaviors.last?.id {
                        Divider()
                    }
                }
                
                if hasMore {
                    Button(action: { showAllBehaviors.toggle() }) {
                        HStack {
                            Text(showAllBehaviors ? "Show Less" : "Show All")
                            Image(systemName: showAllBehaviors ? "chevron.up" : "chevron.down")
                        }
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(theme.surface1)
        .cornerRadius(AppStyles.cardCornerRadius)
        .shadow(color: AppStyles.cardShadow, radius: AppStyles.cardShadowRadius, y: 2)
    }

    private var emptyBehaviorsState: some View {
        VStack(spacing: 8) {
            Text("Set a few ways to earn stars")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
            
            NavigationLink(destination: BehaviorManagementView()) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add Behaviors")
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
    
    private func behaviorRow(behavior: BehaviorType, isPositive: Bool) -> some View {
        HStack(spacing: 12) {
            StyledIcon(
                systemName: behavior.iconName,
                color: isPositive ? AppColors.positive : AppColors.challenge,
                size: 14,
                backgroundSize: 30
            )
            
            Text(behavior.name)
                .font(.body)
            
            Spacer()
            
            HStack(spacing: 2) {
                Text(isPositive ? "+\(behavior.defaultPoints)" : "\(behavior.defaultPoints)")
                    .font(.headline)
                    .foregroundColor(isPositive ? AppColors.positive : .red)
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - My Goals Section
    
    private func myGoalsSection(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                StyledIcon(systemName: "gift.fill", color: .purple, size: 16, backgroundSize: 32, isCircle: true)
                Text("My Goals")
                    .font(.headline)
            }
            
            if activeRewards.isEmpty {
                emptyGoalsState
            } else {
                ForEach(activeRewards) { reward in
                    goalCard(reward: reward, proxy: proxy)
                }
            }
        }
        .padding()
        .background(theme.surface1)
        .cornerRadius(AppStyles.cardCornerRadius)
        .shadow(color: AppStyles.cardShadow, radius: AppStyles.cardShadowRadius, y: 2)
    }

    private var emptyGoalsState: some View {
        VStack(spacing: 8) {
            Text("No goals yet")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)

            Text("Pick something fun to work toward together.")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
    
    private func goalCard(reward: Reward, proxy: ScrollViewProxy) -> some View {
        let isPrimary = rewardsStore.activeReward(forChild: currentChild.id)?.id == reward.id
        let progress = reward.progress(from: behaviorsStore.behaviorEvents, isPrimaryReward: isPrimary)
        let earned = reward.pointsEarnedInWindow(from: behaviorsStore.behaviorEvents, isPrimaryReward: isPrimary)
        let isCovered = agreementsStore.isRewardCoveredByAgreement(rewardId: reward.id, childId: currentChild.id, agreementVersions: rewardsStore.agreementVersions)
        let needsAgreement = !isCovered
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: reward.imageName ?? "gift.fill")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Needs agreement label (top left of title area)
                    if needsAgreement {
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle.fill")
                                .font(.caption2)
                            Text("Needs Agreement")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundColor(.orange)
                    }
                    
                    Text(reward.name)
                        .font(.headline)
                    
                    // Agreement status label - only show "included" if covered
                    if isCovered {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                            Text("Included in agreement")
                                .font(.caption)
                        }
                        .foregroundColor(AppColors.positive)
                    }
                }
                
                Spacer()
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.borderSoft)
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.purple)
                            .frame(width: geometry.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("\(earned) of \(reward.targetPoints) stars")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                    
                    Spacer()
                    
                    if let days = reward.daysRemaining, days > 0 {
                        Text("\(days) \(days == 1 ? "day" : "days") left")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Needs agreement helper and button
            if needsAgreement {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Talk about this goal together, then sign your agreement.")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                    
                    Button(action: {
                        withAnimation {
                            proxy.scrollTo("signatures", anchor: .top)
                        }
                    }) {
                        Text("Review and sign")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.purple)
                            .cornerRadius(20)
                    }
                }
            }
        }
        .padding()
        .background(needsAgreement ? Color.orange.opacity(0.05) : theme.surface2)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(needsAgreement ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    // MARK: - Signature Section
    
    private func signatureSection(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                StyledIcon(systemName: "hand.thumbsup.fill", color: .blue, size: 16, backgroundSize: 32, isCircle: true)
                Text("Our Family Handshake")
                    .font(.headline)
            }
            
            // Different copy based on status
            Text(signatureSubtext)
                .font(.caption)
                .foregroundColor(theme.textSecondary)
            
            // Out of date warning banner
            if coverageStatus == .signedOutOfDate {
                outOfDateBanner
            }
            
            // Signature boxes
            HStack(spacing: 16) {
                // Child signature
                signatureBox(
                    label: currentChild.name,
                    isChild: true
                )
                
                // Parent signature
                signatureBox(
                    label: "Parent",
                    isChild: false
                )
            }
            .opacity(coverageStatus == .signedOutOfDate ? 0.8 : 1.0)
            
            // Helper text for never signed
            if coverageStatus == .neverSigned {
                Text("Draw something fun together to celebrate making your family plan!")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Review and participate again button for out of date
            if coverageStatus == .signedOutOfDate {
                Button(action: {
                    // Start re-participation flow - show child drawing first
                    showingChildSignature = true
                }) {
                    Text("Update Family Handshake")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .cornerRadius(AppStyles.buttonCornerRadius)
                }
            }
        }
        .padding()
        .background(
            theme.surface1
                .overlay(
                    highlightSignatures ?
                    Color.yellow.opacity(0.15) : Color.clear
                )
        )
        .cornerRadius(AppStyles.cardCornerRadius)
        .shadow(color: AppStyles.cardShadow, radius: AppStyles.cardShadowRadius, y: 2)
        .animation(.easeInOut(duration: 0.3), value: highlightSignatures)
    }
    
    private var signatureSubtext: String {
        switch coverageStatus {
        case .neverSigned:
            return "Draw together to celebrate talking about goals!"
        case .signedCurrent:
            return "You talked about this plan together. Great teamwork!"
        case .signedOutOfDate:
            return "Goals have changed. Time for a new family handshake!"
        }
    }
    
    private var outOfDateBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundColor(.orange)
            Text("Goals have changed! Talk about the new plan and do a new family handshake.")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.15))
        .cornerRadius(8)
    }
    
    private func signatureBox(label: String, isChild: Bool) -> some View {
        let isSigned = isChild ? currentChild.childSignature.isSigned : currentChild.parentSignature.isSigned
        let signatureData = isChild ? currentChild.childSignature.signatureData : currentChild.parentSignature.signatureData
        let signedDate = isChild ? currentChild.childSignature.signedAt : currentChild.parentSignature.signedAt
        
        return Button(action: {
            if isChild {
                showingChildSignature = true
            } else {
                showingParentSignature = true
            }
        }) {
            VStack(spacing: 8) {
                // Signature area
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            signatureStrokeColor(isSigned: isSigned),
                            style: StrokeStyle(lineWidth: 1, dash: isSigned ? [] : [5])
                        )
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.surface2)
                        )
                    
                    if isSigned, let data = signatureData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 50)
                            .cornerRadius(6)
                    } else {
                        // Placeholder text for unsigned
                        Text("Tap to draw")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                
                // Status text
                VStack(spacing: 2) {
                    if isSigned {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.thumbsup.fill")
                                .foregroundColor(AppColors.positive)
                                .font(.caption)
                            Text(isChild ? "\(currentChild.name) participated" : "Parent participated")
                                .font(.caption.weight(.medium))
                                .foregroundColor(AppColors.positive)
                        }

                        if let date = signedDate {
                            Text(participationDateLabel(date))
                                .font(.caption2)
                                .foregroundColor(theme.textSecondary)
                        }
                    } else {
                        Text(isChild ? "\(currentChild.name)'s turn to draw" : "Parent's turn to draw")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
    
    private func signatureStrokeColor(isSigned: Bool) -> Color {
        if !isSigned {
            return Theme().borderStrong
        }
        switch coverageStatus {
        case .signedCurrent:
            return AppColors.positive
        case .signedOutOfDate, .neverSigned:
            return AppColors.positive.opacity(0.6)
        }
    }
    
    private func participationDateLabel(_ date: Date) -> String {
        let formatted = formattedDate(date)
        switch coverageStatus {
        case .signedCurrent, .neverSigned:
            return "Joined on \(formatted)"
        case .signedOutOfDate:
            return "Last joined on \(formatted)"
        }
    }
    
    // MARK: - Helpers
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
    
    private func shareAgreement() {
        // Create a visual representation of the agreement
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 600))
        let image = renderer.image { context in
            // Draw background
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 400, height: 600))
            
            // Draw title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            let title = "\(currentChild.name)'s Agreement"
            title.draw(at: CGPoint(x: 20, y: 20), withAttributes: titleAttributes)
            
            // Draw date
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.gray
            ]
            let dateText = "Created: \(formattedDate(Date()))"
            dateText.draw(at: CGPoint(x: 20, y: 50), withAttributes: dateAttributes)
        }
        
        agreementImage = image
        showingShareSheet = true
    }
}

// MARK: - Participation Sheet (Fun Drawing Activity)

enum SignatureType {
    case child
    case parent
}

/// A fun drawing activity to celebrate making a family plan together.
/// This is NOT a legal signature - just a celebratory participation activity.
struct ParticipationSheet: View {
    let type: SignatureType
    let childName: String
    let onComplete: (Data) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @State private var paths: [Path] = []
    @State private var currentPath = Path()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Instructions
                Text(instructionText)
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Canvas
                VStack(spacing: 8) {
                    Canvas { context, size in
                        for path in paths {
                            context.stroke(path, with: .color(.primary), lineWidth: 3)
                        }
                        context.stroke(currentPath, with: .color(.primary), lineWidth: 3)
                    }
                    .frame(height: 150)
                    .background(Theme().surface2)
                    .cornerRadius(12)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let point = value.location
                                if currentPath.isEmpty {
                                    currentPath.move(to: point)
                                } else {
                                    currentPath.addLine(to: point)
                                }
                            }
                            .onEnded { _ in
                                paths.append(currentPath)
                                currentPath = Path()
                            }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme().borderStrong, lineWidth: 1)
                    )

                    HStack {
                        Button(action: clearDrawing) {
                            Label("Clear", systemImage: "arrow.counterclockwise")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }

                        Spacer()

                        Text("Draw with your finger")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Complete button
                Button(action: saveDrawing) {
                    Text(type == .child ? "I'm In! 🎉" : "Let's Do This!")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(paths.isEmpty ? theme.borderStrong : AppColors.positive)
                        .foregroundColor(.white)
                        .cornerRadius(AppStyles.buttonCornerRadius)
                }
                .disabled(paths.isEmpty)
                .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationTitle(type == .child ? "\(childName)'s Drawing" : "Parent's Drawing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var instructionText: String {
        if type == .child {
            return "You talked about your goals with a grown-up! Draw something fun to celebrate. 🌟"
        } else {
            return "You discussed the family plan together. Draw something to mark this moment!"
        }
    }

    private func clearDrawing() {
        paths.removeAll()
        currentPath = Path()
    }

    private func saveDrawing() {
        // Render drawing to image
        let size = CGSize(width: 300, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.systemGray6.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            UIColor.label.setStroke()
            let cgContext = context.cgContext
            cgContext.setLineWidth(3)
            cgContext.setLineCap(.round)

            // Scale paths to fit
            let scale = min(size.width / 350, size.height / 150)
            cgContext.scaleBy(x: scale, y: scale)

            for path in paths {
                cgContext.addPath(path.cgPath)
            }
            cgContext.strokePath()
        }

        if let data = image.pngData() {
            onComplete(data)
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    let repository = Repository.preview
    FamilyAgreementView(child: Child(name: "Emma", age: 8, colorTag: .purple))
        .environmentObject(repository)
        .environmentObject(BehaviorsStore(repository: repository))
        .environmentObject(AgreementsStore(repository: repository))
}
