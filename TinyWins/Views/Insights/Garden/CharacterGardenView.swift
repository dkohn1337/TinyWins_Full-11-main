import SwiftUI

// MARK: - Character Garden View

/// A beautiful garden visualization showing character trait development.
/// Each trait is represented as a plant that grows based on logged moments.
///
/// ## Design Philosophy
/// - Delivers clear value in 5-10 seconds via hero message
/// - All plants are always healthy - just different sizes
/// - Seeds represent "potential waiting to bloom", not failure
/// - Celebrates growth with warm, encouraging copy
/// - Perfect for time-pressed parents wanting quick insights
struct CharacterGardenView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    @Bindable var viewModel: CharacterGardenViewModel
    @State private var selectedPlant: GardenPlant?
    @State private var selectedTimeRange: GardenTimeRange = .thisWeek

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero message - the 5-10 second value
                heroSection

                // Time range selector
                timeRangeSelector

                // Selected plant detail (if any) - ABOVE grid so no scroll needed
                if let plant = selectedPlant {
                    plantDetailCard(plant)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .opacity
                        ))
                }

                // The garden grid
                gardenGrid

                // Garden summary
                gardenSummary

                // Encouragement footer
                encouragementFooter
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.bottom, 120) // Account for tab bar
        }
        .background(gardenBackground)
        .navigationTitle("\(viewModel.child.name)'s Garden")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            // Sync local state with viewModel
            selectedTimeRange = viewModel.timeRange
        }
        .onChange(of: selectedTimeRange) { _, newValue in
            viewModel.timeRange = newValue
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 12) {
            if let heroMessage = viewModel.heroMessage {
                // Mood-based icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: heroMessage.mood == .celebration
                                    ? [Color.yellow.opacity(0.3), Color.orange.opacity(0.2)]
                                    : [Color.green.opacity(0.2), Color.teal.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: heroMessage.mood == .celebration ? "sparkles" : "leaf.fill")
                        .font(.system(size: 24))
                        .foregroundColor(heroMessage.mood == .celebration ? .orange : .green)
                }

                // Headline
                Text(heroMessage.headline)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)

                // Subheadline
                Text(heroMessage.subheadline)
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)

                // Trait color accent if specific trait
                if let trait = heroMessage.trait {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(trait.color)
                            .frame(width: 8, height: 8)

                        Text(trait.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(trait.color)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(trait.color.opacity(0.12))
                    )
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.surface1)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.green.opacity(0.08),
                                    Color.yellow.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: Color.green.opacity(0.1), radius: 10, y: 4)
        )
    }

    // MARK: - Time Range Selector

    private var timeRangeSelector: some View {
        HStack(spacing: 0) {
            ForEach(GardenTimeRange.allCases) { range in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTimeRange = range
                        selectedPlant = nil
                    }
                } label: {
                    Text(range.displayName)
                        .font(.subheadline)
                        .fontWeight(selectedTimeRange == range ? .semibold : .regular)
                        .foregroundColor(selectedTimeRange == range ? .white : theme.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if selectedTimeRange == range {
                                    Capsule()
                                        .fill(Color.green)
                                }
                            }
                        )
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(theme.surface1)
                .shadow(color: Color.black.opacity(0.08), radius: 6, y: 2)
        )
    }

    // MARK: - Garden Grid

    private var gardenGrid: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)

                Text("Character Garden")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)

                Spacer()

                Text("Tap to explore")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }

            // 2x3 grid of plants
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ],
                spacing: 12
            ) {
                ForEach(viewModel.plants, id: \.trait) { plant in
                    GardenPlantView(
                        plant: plant,
                        isSelected: selectedPlant?.trait == plant.trait,
                        onTap: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                if selectedPlant?.trait == plant.trait {
                                    selectedPlant = nil
                                } else {
                                    selectedPlant = plant
                                }
                            }
                        }
                    )
                    .id(plant.trait) // Stable identity
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.surface1)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        )
    }

    // MARK: - Plant Detail Card

    private func plantDetailCard(_ plant: GardenPlant) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with trait info
            HStack(spacing: 12) {
                // Trait icon circle
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [plant.trait.color, plant.trait.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: plant.trait.color.opacity(0.3), radius: 4, y: 2)

                    Image(systemName: plant.trait.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(plant.trait.displayName)
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)

                    Text(plant.stageDescription)
                        .font(.subheadline)
                        .foregroundColor(plant.trait.color)
                }

                Spacer()

                // Close button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedPlant = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(theme.textDisabled.opacity(0.5))
                }
                .buttonStyle(.plain)
            }

            // Trait description
            Text(plant.trait.description)
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)

            Divider()

            // Stats row
            HStack(spacing: 24) {
                // Moments
                VStack(spacing: 4) {
                    Text("\(plant.moments)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(plant.trait.color)

                    Text("Moments")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }

                // Points
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Text("\(plant.points)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)

                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.yellow)
                    }

                    Text("Points earned")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()

                // Encouragement badge
                Text(plant.encouragement)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [plant.trait.color, plant.trait.color.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }

            // Growth tip based on stage
            if plant.stage != .fullBloom {
                growthTip(for: plant)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.surface1)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [plant.trait.color.opacity(0.08), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: plant.trait.color.opacity(0.15), radius: 8, y: 4)
        )
    }

    private func growthTip(for plant: GardenPlant) -> some View {
        let momentsToNext = momentsNeededForNextStage(plant)

        return HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)

            Text(momentsToNext > 0
                ? "\(momentsToNext) more \(plant.trait.displayName.lowercased()) moment\(momentsToNext == 1 ? "" : "s") to reach the next stage"
                : "Keep nurturing this beautiful trait!"
            )
            .font(.caption)
            .foregroundColor(theme.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.yellow.opacity(0.1))
        )
    }

    private func momentsNeededForNextStage(_ plant: GardenPlant) -> Int {
        switch plant.stage {
        case .seedling:
            return 1 - plant.moments
        case .sprout:
            return (CharacterGardenViewModel.sproutMax + 1) - plant.moments
        case .youngPlant:
            return (CharacterGardenViewModel.youngPlantMax + 1) - plant.moments
        case .budding:
            return (CharacterGardenViewModel.buddingMax + 1) - plant.moments
        case .blooming:
            return (CharacterGardenViewModel.bloomingMax + 1) - plant.moments
        case .fullBloom:
            return 0
        }
    }

    // MARK: - Garden Summary

    /// Short display name for summary card (avoids 2-line wrapping)
    private var timeRangeShortName: String {
        switch selectedTimeRange {
        case .thisWeek: return "Week"
        case .thisMonth: return "Month"
        case .allTime: return "All"
        }
    }

    private var gardenSummary: some View {
        HStack(spacing: 12) {
            // Total moments
            summaryItem(
                value: "\(viewModel.totalMoments)",
                label: "Moments",
                icon: "heart.fill",
                color: .pink
            )

            Divider()
                .frame(height: 40)

            // Growing traits
            summaryItem(
                value: "\(viewModel.growingTraits)/6",
                label: "Growing",
                icon: "leaf.fill",
                color: .green
            )

            Divider()
                .frame(height: 40)

            // Time range
            summaryItem(
                value: timeRangeShortName,
                label: "Period",
                icon: "calendar",
                color: .blue
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.surface1)
                .shadow(color: Color.black.opacity(0.05), radius: 6, y: 3)
        )
    }

    private func summaryItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)

                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(theme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Encouragement Footer

    private var encouragementFooter: some View {
        VStack(spacing: 8) {
            Text("Every moment nurtures growth")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.textPrimary)

            Text("Log positive moments to watch the garden flourish")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.green.opacity(0.08),
                            Color.yellow.opacity(0.05),
                            Color.green.opacity(0.08)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
    }

    // MARK: - Background

    private var gardenBackground: some View {
        ZStack {
            // Base color
            theme.bg0

            // Subtle garden gradient
            LinearGradient(
                colors: [
                    Color.green.opacity(0.03),
                    Color.clear,
                    Color.yellow.opacity(0.02)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Preview

#Preview("Character Garden - With Data") {
    let repository = Repository.preview
    let child = repository.appData.children.first ?? Child(name: "Emma", colorTag: .coral)
    let viewModel = CharacterGardenViewModel(
        child: child,
        events: repository.appData.behaviorEvents,
        behaviorTypes: repository.appData.behaviorTypes
    )

    NavigationStack {
        CharacterGardenView(viewModel: viewModel)
    }
    .withTheme(Theme())
}

#Preview("Character Garden - Empty State") {
    let child = Child(name: "Liam", colorTag: .blue)
    let viewModel = CharacterGardenViewModel(
        child: child,
        events: [],
        behaviorTypes: []
    )

    NavigationStack {
        CharacterGardenView(viewModel: viewModel)
    }
    .withTheme(Theme())
}
