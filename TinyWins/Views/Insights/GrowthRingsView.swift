import SwiftUI

// MARK: - GrowthRingsView

/// Beautiful circular visualization showing character trait development over time.
/// Inner rings = older data, outer rings = recent.
/// Each segment colored by trait strength.
///
/// ## Features
/// - Time range selector (This Week, Last 4 Weeks, Last 6 Months)
/// - Parent Brief card with highlights and suggestions
/// - Interactive trait selection
/// - Bucket (week/month) selector
/// - Sample size guardrails
struct GrowthRingsView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @EnvironmentObject private var repository: Repository

    let child: Child

    @State private var viewModel: GrowthRingsViewModel?
    @State private var isAnimating = false
    @State private var showingTraitDetail = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time Range Picker
                timeRangePicker

                // Parent Brief Card (premium highlight)
                if let brief = viewModel?.parentBrief {
                    parentBriefCard(brief)
                }

                // Growth Rings Visualization
                growthRingsSection

                // Legend + Trait Selector
                legendSection

                // Bucket Details (when selected)
                if let bucket = viewModel?.selectedBucket {
                    bucketDetailSection(bucket)
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.vertical, 16)
            .tabBarBottomPadding()
        }
        .background(
            LinearGradient(
                colors: [
                    theme.bg0,
                    Color.purple.opacity(0.02),
                    theme.bg0
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .accessibilityIdentifier(InsightsAccessibilityIdentifiers.growthRingsRoot)
        .navigationTitle(Text("Growth Rings", tableName: "Insights"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            initializeViewModel()
            withAnimation(.easeOut(duration: 1.0)) {
                isAnimating = true
            }
        }
        .sheet(isPresented: $showingTraitDetail) {
            if let trait = viewModel?.selectedTrait {
                traitDetailSheet(trait)
            }
        }
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        HStack(spacing: 8) {
            ForEach(GrowthRingsTimeRange.allCases) { range in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel?.timeRange = range
                    }
                } label: {
                    Text(range.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(viewModel?.timeRange == range ? .white : theme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(viewModel?.timeRange == range ?
                                      theme.accentPrimary : theme.surface1)
                        )
                        .overlay(
                            Capsule()
                                .stroke(viewModel?.timeRange == range ?
                                        Color.clear : theme.accentPrimary.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Time range selector", tableName: "Insights"))
    }

    // MARK: - Parent Brief Card

    private func parentBriefCard(_ brief: ParentBrief) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with warm styling
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.yellow, Color.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .shadow(color: Color.orange.opacity(0.3), radius: 4, y: 2)

                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("This Period's Highlight", tableName: "Insights")
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)

                    if let bucketLabel = viewModel?.selectedBucket?.labelLong {
                        Text(bucketLabel)
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }

                Spacer()

                // Trend indicator
                if brief.previousBucketExists {
                    trendBadge(brief.trend)
                }
            }

            // Strongest trait highlight
            if let trait = brief.strongestTrait {
                HStack(spacing: 12) {
                    Image(systemName: trait.icon)
                        .font(.title2)
                        .foregroundColor(trait.color)
                        .frame(width: 44, height: 44)
                        .background(trait.color.opacity(0.15))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(trait.displayName)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(theme.textPrimary)

                        Text("is shining brightest", tableName: "Insights")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                    }

                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(trait.color.opacity(0.08))
                )
            }

            // Stats row
            HStack(spacing: 16) {
                statChip(
                    icon: "star.fill",
                    value: "\(brief.momentsCount)",
                    label: String(localized: "moments", table: "Insights"),
                    color: .yellow
                )

                statChip(
                    icon: "sparkle",
                    value: "\(brief.pointsCount)",
                    label: String(localized: "points", table: "Insights"),
                    color: theme.success
                )
            }

            // Suggestions (if has minimum data)
            if brief.hasMinimumData && !brief.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)

                        Text("Try this", tableName: "Insights")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.success)
                    }

                    Text(brief.suggestions.first ?? "")
                        .font(.subheadline)
                        .foregroundColor(theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.yellow.opacity(0.08))
                )
            }

            // Low data guardrail
            if !brief.hasMinimumData {
                lowDataNotice
            }
        }
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(theme.surface1)

                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.06), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(Color.yellow.opacity(0.15), lineWidth: 1)
            }
        )
        .shadow(color: Color.orange.opacity(0.08), radius: 8, y: 4)
    }

    private func trendBadge(_ trend: TrendDirection) -> some View {
        HStack(spacing: 4) {
            Image(systemName: trend.icon)
                .font(.system(size: 11, weight: .bold))

            Text(trendLabel(trend))
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(trend.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(trend.color.opacity(0.12))
        )
    }

    private func trendLabel(_ trend: TrendDirection) -> LocalizedStringKey {
        switch trend {
        case .up: return "Growing"
        case .down: return "Quieter"
        case .flat: return "Steady"
        case .noData: return "New"
        }
    }

    private func statChip(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)

                Text(label)
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.08))
        )
    }

    private var lowDataNotice: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)

            Text("Log a few more moments to unlock detailed insights", tableName: "Insights")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.08))
        )
    }

    // MARK: - Growth Rings Section

    private var growthRingsSection: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("\(child.name)'s Character Growth", tableName: "Insights")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)

                Spacer()
            }

            // Ring visualization in square container
            GeometryReader { geometry in
                let size = min(geometry.size.width, 320)

                ZStack {
                    // Background circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [theme.surface2.opacity(0.3), theme.surface2.opacity(0.6)],
                                center: .center,
                                startRadius: 20,
                                endRadius: size / 2
                            )
                        )

                    // Growth rings
                    if let buckets = viewModel?.buckets {
                        ForEach(Array(buckets.enumerated()), id: \.element.id) { index, bucket in
                            GrowthRingLayer(
                                bucket: bucket,
                                ringIndex: index,
                                totalRings: buckets.count,
                                isAnimating: isAnimating,
                                selectedTrait: viewModel?.selectedTrait,
                                isSelected: viewModel?.selectedBucket?.id == bucket.id
                            )
                            .opacity(viewModel?.selectedBucket == nil ||
                                     viewModel?.selectedBucket?.id == bucket.id ? 1 : 0.4)
                        }
                    }

                    // Center Label
                    centerLabel
                }
                .frame(width: size, height: size)
                .frame(maxWidth: .infinity)
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxHeight: dynamicTypeSize.isAccessibilitySize ? 250 : 320)

            // Bucket selector
            bucketSelector
        }
        .padding(18)
        .background(theme.surface1)
        .cornerRadius(theme.cornerRadius)
        .shadow(color: theme.shadowColor.opacity(theme.shadowStrength), radius: 8, y: 2)
    }

    private var centerLabel: some View {
        VStack(spacing: 4) {
            if let bucket = viewModel?.selectedBucket {
                Text(bucket.labelShort)
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)

                if bucket.hasMinimumData {
                    Text("\(bucket.totalMoments) moments", tableName: "Insights")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
            } else {
                Text(viewModel?.timeRange.shortName ?? "")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)

                Text("growth", tableName: "Insights")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding(16)
        .background(
            Circle()
                .fill(theme.surface1)
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        )
    }

    private var bucketSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(viewModel?.buckets ?? []) { bucket in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            if viewModel?.selectedBucket?.id == bucket.id {
                                viewModel?.selectBucket(nil)
                            } else {
                                viewModel?.selectBucket(bucket)
                            }
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(bucket.labelShort)
                                .font(.caption)
                                .fontWeight(viewModel?.selectedBucket?.id == bucket.id ? .bold : .regular)

                            // Data indicator dot
                            Circle()
                                .fill(bucket.hasMinimumData ? theme.success : theme.textDisabled.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                        .foregroundColor(viewModel?.selectedBucket?.id == bucket.id ? .white : theme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(viewModel?.selectedBucket?.id == bucket.id ?
                                      theme.accentPrimary : theme.surface2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Legend Section

    private var legendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Character Traits", tableName: "Insights")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)

                Spacer()

                Text("Tap to explore", tableName: "Insights")
                    .font(.caption)
                    .foregroundColor(theme.accentPrimary)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(CharacterTrait.allCases) { trait in
                    legendItem(trait: trait)
                }
            }
        }
        .padding(18)
        .background(theme.surface1)
        .cornerRadius(theme.cornerRadius)
        .shadow(color: theme.shadowColor.opacity(theme.shadowStrength), radius: 8, y: 2)
    }

    private func legendItem(trait: CharacterTrait) -> some View {
        let isSelected = viewModel?.selectedTrait == trait

        return Button {
            withAnimation(.spring(response: 0.3)) {
                if isSelected {
                    viewModel?.selectTrait(nil)
                } else {
                    viewModel?.selectTrait(trait)
                }
            }
        } label: {
            HStack(spacing: 10) {
                // Trait color dot with gradient - larger and more prominent
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [trait.color, trait.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 20, height: 20)
                    .shadow(color: trait.color.opacity(0.4), radius: 3, y: 1)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: isSelected ? 2 : 0)
                    )

                Text(trait.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(theme.textPrimary)

                Spacer()

                // Score indicator OR chevron
                if let bucket = viewModel?.selectedBucket,
                   let score = bucket.traitScores[trait],
                   score.moments > 0 {
                    Text("\(score.moments)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(trait.color)
                        )
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(trait.color.opacity(0.6))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? trait.color.opacity(0.15) : theme.surface1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? trait.color.opacity(0.4) : trait.color.opacity(0.15),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(trait.displayName) character trait - tap to explore", tableName: "Insights"))
    }

    // MARK: - Bucket Detail Section

    private func bucketDetailSection(_ bucket: GrowthRingsBucket) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(bucket.labelLong)
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)

                Spacer()

                if bucket.isCurrentPeriod {
                    Text("Current", tableName: "Insights")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(theme.accentPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(theme.accentPrimary.opacity(0.12))
                        )
                }
            }

            if bucket.hasMinimumData {
                // Top traits for this bucket
                let sortedTraits = CharacterTrait.allCases.sorted {
                    (bucket.traitScores[$0]?.points ?? 0) > (bucket.traitScores[$1]?.points ?? 0)
                }

                ForEach(sortedTraits.prefix(3)) { trait in
                    if let score = bucket.traitScores[trait], score.moments > 0 {
                        traitProgressRow(trait: trait, score: score, bucket: bucket)
                    }
                }
            } else {
                // Low data state
                HStack(spacing: 12) {
                    Image(systemName: "leaf.fill")
                        .font(.title2)
                        .foregroundColor(.green)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Growing period", tableName: "Insights")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(theme.textPrimary)

                        Text("Log \(GrowthRingsViewModel.minimumMomentsPerBucket - bucket.totalMoments) more moments to see traits emerge", tableName: "Insights")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.08))
                )
            }
        }
        .padding(18)
        .background(theme.surface1)
        .cornerRadius(theme.cornerRadius)
        .shadow(color: theme.shadowColor.opacity(theme.shadowStrength), radius: 8, y: 2)
    }

    private func traitProgressRow(trait: CharacterTrait, score: TraitBucketScore, bucket: GrowthRingsBucket) -> some View {
        Button {
            viewModel?.selectTrait(trait)
            showingTraitDetail = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: trait.icon)
                    .font(.title3)
                    .foregroundColor(trait.color)
                    .frame(width: 36, height: 36)
                    .background(trait.color.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(trait.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.textPrimary)

                    Text("\(score.moments) moments • \(score.points) points", tableName: "Insights")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()

                // Progress bar
                GeometryReader { geometry in
                    let maxPoints = bucket.traitScores.values.map { $0.points }.max() ?? 1
                    let width = maxPoints > 0 ? CGFloat(score.points) / CGFloat(maxPoints) : 0

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(theme.borderSoft)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [trait.color, trait.color.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * width)
                    }
                }
                .frame(width: 60, height: 8)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary.opacity(0.5))
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Trait Detail Sheet

    private func traitDetailSheet(_ trait: CharacterTrait) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Trait header
                    HStack(spacing: 14) {
                        Image(systemName: trait.icon)
                            .font(.largeTitle)
                            .foregroundColor(trait.color)
                            .frame(width: 60, height: 60)
                            .background(trait.color.opacity(0.15))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(trait.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(theme.textPrimary)

                            Text(trait.description)
                                .font(.subheadline)
                                .foregroundColor(theme.textSecondary)
                        }
                    }

                    // Trend mini-chart
                    if let data = viewModel?.traitDetailData(for: trait) {
                        traitTrendSection(data)
                    }

                    // Related behaviors
                    relatedBehaviorsSection(trait)
                }
                .padding(AppSpacing.screenPadding)
            }
            .background(theme.bg0.ignoresSafeArea())
            .navigationTitle(trait.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { showingTraitDetail = false }) {
                        Text("Done", tableName: "Common")
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func traitTrendSection(_ data: TraitDetailData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Trend", tableName: "Insights")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)

                Spacer()

                trendBadge(data.trend)
            }

            // Mini trend chart
            if !data.trendValues.isEmpty {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(Array(data.trendValues.enumerated()), id: \.offset) { index, value in
                        let maxValue = data.trendValues.max() ?? 1
                        let height = maxValue > 0 ? CGFloat(value) / CGFloat(maxValue) * 60 : 0

                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [data.trait.color, data.trait.color.opacity(0.6)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 24, height: max(8, height))

                            if let bucket = viewModel?.buckets[safe: index] {
                                Text(bucket.labelShort)
                                    .font(.system(size: 9))
                                    .foregroundColor(theme.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            // Current period stats
            HStack(spacing: 16) {
                statChip(
                    icon: "star.fill",
                    value: "\(data.currentMoments)",
                    label: String(localized: "moments", table: "Insights"),
                    color: data.trait.color
                )

                statChip(
                    icon: "sparkle",
                    value: "\(data.currentPoints)",
                    label: String(localized: "points", table: "Insights"),
                    color: data.trait.color
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.surface1)
        )
    }

    private func relatedBehaviorsSection(_ trait: CharacterTrait) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Behaviors", tableName: "Insights")
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            let relatedBehaviors = getRelatedBehaviors(for: trait)

            if relatedBehaviors.isEmpty {
                Text("No specific behaviors mapped yet", tableName: "Insights")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
            } else {
                ForEach(relatedBehaviors.prefix(6), id: \.self) { behaviorName in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(trait.color)

                        Text(behaviorName)
                            .font(.subheadline)
                            .foregroundColor(theme.textPrimary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.surface1)
        )
    }

    // MARK: - Initialization

    private func initializeViewModel() {
        guard viewModel == nil else { return }

        viewModel = GrowthRingsViewModel(
            child: child,
            events: repository.appData.behaviorEvents,
            behaviorTypes: repository.appData.behaviorTypes
        )
    }

    private func getRelatedBehaviors(for trait: CharacterTrait) -> [String] {
        repository.appData.behaviorTypes
            .filter { behaviorType in
                CharacterTrait.traitsForBehavior(behaviorType.name).contains(trait)
            }
            .map { $0.name }
    }
}

// MARK: - Growth Ring Layer

/// A single ring in the growth visualization.
struct GrowthRingLayer: View {
    let bucket: GrowthRingsBucket
    let ringIndex: Int
    let totalRings: Int
    let isAnimating: Bool
    let selectedTrait: CharacterTrait?
    let isSelected: Bool

    private let baseRadius: CGFloat = 25
    private let ringWidth: CGFloat = 28

    var body: some View {
        let radius = baseRadius + CGFloat(ringIndex + 1) * ringWidth
        let traits = CharacterTrait.allCases

        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let scale = min(geometry.size.width, geometry.size.height) / 320

            ZStack {
                ForEach(Array(traits.enumerated()), id: \.element.id) { traitIndex, trait in
                    let startAngle = Angle(degrees: Double(traitIndex) * (360.0 / Double(traits.count)) - 90)
                    let endAngle = Angle(degrees: Double(traitIndex + 1) * (360.0 / Double(traits.count)) - 90)
                    let score = bucket.normalizedScore(for: trait)

                    RingSegment(
                        innerRadius: (radius - ringWidth / 2) * scale,
                        outerRadius: (radius + ringWidth / 2 - 2) * scale,
                        startAngle: startAngle,
                        endAngle: endAngle
                    )
                    .fill(
                        LinearGradient(
                            colors: [
                                trait.color.opacity(score * 0.7 + 0.15),
                                trait.color.opacity(score * 0.5 + 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isAnimating ? 1 : 0.5)
                    .opacity(isAnimating ? (selectedTrait == nil || selectedTrait == trait ? 1 : 0.25) : 0)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.7)
                        .delay(Double(ringIndex) * 0.1 + Double(traitIndex) * 0.02),
                        value: isAnimating
                    )
                    .animation(.easeInOut(duration: 0.2), value: selectedTrait)
                }

                // Selection ring highlight
                if isSelected {
                    Circle()
                        .stroke(Color.white.opacity(0.8), lineWidth: 2)
                        .frame(
                            width: (radius + ringWidth / 2) * 2 * scale,
                            height: (radius + ringWidth / 2) * 2 * scale
                        )
                        .position(center)
                }
            }
        }
    }
}

// MARK: - Ring Segment Shape

/// Custom shape for a ring segment (arc with thickness).
struct RingSegment: Shape {
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)

        // Outer arc
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )

        // Line to inner arc
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )

        path.closeSubpath()

        return path
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GrowthRingsView(child: Child.preview)
    }
    .environmentObject(Repository.preview)
    .withTheme(Theme())
}

// MARK: - Child Preview Extension

extension Child {
    static var preview: Child {
        Child(
            name: "Emma",
            age: 7,
            colorTag: .purple,
            totalPoints: 45
        )
    }
}
