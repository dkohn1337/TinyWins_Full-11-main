import Foundation

// MARK: - Debug Report

/// Comprehensive debug report for the insights engine.
/// Allows developers to diagnose "why didn't I get a card?" in under 2 minutes.
struct InsightsDebugReport: Equatable {
    let childId: String
    let childName: String?
    let generatedAt: Date
    let signalResults: [SignalResult]
    let builtCards: [CoachCard]           // All cards built from triggered signals
    let droppedCards: [DroppedCard]       // Cards dropped with reasons
    let selectedCards: [CoachCard]        // Final cards after all filtering
    let activeCooldowns: [CooldownInfo]
    let dataStats: DataStats

    struct CooldownInfo: Equatable {
        let templateId: String
        let childId: String
        let endsAt: Date
    }

    struct DroppedCard: Equatable {
        let card: CoachCard
        let reason: DropReason
        let details: String

        enum DropReason: String, Equatable {
            case evidenceInvalid = "Evidence Invalid"
            case cooldownActive = "Cooldown Active"
            case safetyRailRisk = "Safety Rail: Max Risk Cards"
            case safetyRailImprovement = "Safety Rail: Max Improvement Cards"
            case rankingCutoff = "Below Ranking Cutoff"
        }
    }

    struct DataStats: Equatable {
        let totalEvents14Days: Int
        let positiveEvents7Days: Int
        let challengeEvents7Days: Int
        let routineEvents7Days: Int
        let activeGoals: Int
        let routineBehaviors: Int
    }

    // MARK: - Computed Properties

    var triggeredSignals: [SignalResult] {
        signalResults.filter { $0.triggered }
    }

    var notTriggeredSignals: [SignalResult] {
        signalResults.filter { !$0.triggered }
    }

    var hasInsufficientData: Bool {
        dataStats.totalEvents14Days < InsightsEngineConstants.minimumEventsForInsight
    }

    var cardsSummary: String {
        "Built: \(builtCards.count) → Dropped: \(droppedCards.count) → Selected: \(selectedCards.count)"
    }

    // MARK: - Formatted Output

    func formattedReport() -> String {
        var lines: [String] = []

        lines.append("=== INSIGHTS ENGINE DEBUG REPORT ===")
        lines.append("Generated: \(formatDate(generatedAt))")
        lines.append("Child: \(childName ?? "Unknown") (\(childId))")
        lines.append("Pipeline: \(cardsSummary)")
        lines.append("")

        // Data Stats
        lines.append("--- DATA STATS ---")
        lines.append("Events (14 days): \(dataStats.totalEvents14Days)")
        lines.append("  Positive (7 days): \(dataStats.positiveEvents7Days)")
        lines.append("  Challenges (7 days): \(dataStats.challengeEvents7Days)")
        lines.append("  Routines (7 days): \(dataStats.routineEvents7Days)")
        lines.append("Active Goals: \(dataStats.activeGoals)")
        lines.append("Routine Behaviors: \(dataStats.routineBehaviors)")
        lines.append("")

        // Triggered Signals (table format)
        lines.append("--- SIGNAL RESULTS ---")
        lines.append("| Signal | Triggered | Confidence | Evidence | Entity |")
        lines.append("|--------|-----------|------------|----------|--------|")
        for signal in signalResults {
            let triggered = signal.triggered ? "YES" : "no"
            let confidence = signal.triggered ? String(format: "%.0f%%", signal.confidence * 100) : "-"
            let evidence = signal.triggered ? "\(signal.evidence.count)" : "-"
            let entity = signal.metadata.goalName ?? signal.metadata.behaviorName ?? "-"
            lines.append("| \(signal.signalType.rawValue) | \(triggered) | \(confidence) | \(evidence) | \(entity) |")
        }
        lines.append("")

        // Not Triggered Details
        if !notTriggeredSignals.isEmpty {
            lines.append("--- NOT TRIGGERED REASONS ---")
            for signal in notTriggeredSignals {
                lines.append("[\(signal.signalType.rawValue)] \(signal.explanation)")
            }
            lines.append("")
        }

        // Built Cards
        lines.append("--- BUILT CARDS (\(builtCards.count)) ---")
        for card in builtCards {
            lines.append("[\(card.templateId)] P\(card.priority) | \(card.title)")
        }
        lines.append("")

        // Dropped Cards (actionable!)
        if !droppedCards.isEmpty {
            lines.append("--- DROPPED CARDS (\(droppedCards.count)) ---")
            for dropped in droppedCards {
                lines.append("[\(dropped.card.templateId)] \(dropped.reason.rawValue)")
                lines.append("  Details: \(dropped.details)")
            }
            lines.append("")
        }

        // Selected Cards
        lines.append("--- SELECTED CARDS (\(selectedCards.count)) ---")
        for (index, card) in selectedCards.enumerated() {
            lines.append("\(index + 1). \(card.title)")
            lines.append("   Template: \(card.templateId)")
            lines.append("   Priority: \(card.priority)")
            lines.append("   Evidence: \(card.evidenceEventIds.count) events")
            lines.append("   StableKey: \(card.stableKey)")
            lines.append("   CTA: \(card.cta.buttonText)")
            lines.append("")
        }

        // Active Cooldowns
        lines.append("--- ACTIVE COOLDOWNS (\(activeCooldowns.count)) ---")
        if activeCooldowns.isEmpty {
            lines.append("(none)")
        } else {
            for cooldown in activeCooldowns {
                lines.append("[\(cooldown.templateId)] ends \(formatDate(cooldown.endsAt))")
            }
        }

        lines.append("")
        lines.append("=== END REPORT ===")

        return lines.joined(separator: "\n")
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Debug View (Non-Production)

#if DEBUG
import SwiftUI

struct InsightsEngineDebugView: View {
    @EnvironmentObject private var repository: Repository
    @EnvironmentObject private var childrenStore: ChildrenStore

    @State private var selectedChildId: String?
    @State private var report: InsightsDebugReport?
    @State private var isLoading = false
    @State private var showingUnitTests = false
    @State private var testResults: [(name: String, passed: Bool)] = []
    @State private var isRunningTests = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Child Picker
                    childPicker

                    if isLoading {
                        ProgressView("Generating report...")
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if let report = report {
                        reportContent(report)
                    } else {
                        Text("Select a child to generate a debug report")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Insights Engine Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Unit Tests") {
                        showingUnitTests = true
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Refresh") {
                        generateReport()
                    }
                    .disabled(selectedChildId == nil)
                }
            }
            .sheet(isPresented: $showingUnitTests) {
                unitTestsSheet
            }
        }
    }

    // MARK: - Unit Tests Sheet

    private var unitTestsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isRunningTests {
                        ProgressView("Running tests...")
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if testResults.isEmpty {
                        VStack(spacing: 12) {
                            Text("Insights Engine Unit Tests")
                                .font(.headline)
                            Text("Run all unit tests to verify engine correctness.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Run All Tests") {
                                runUnitTests()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        unitTestResultsView
                    }
                }
                .padding()
            }
            .navigationTitle("Unit Tests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingUnitTests = false
                    }
                }
            }
        }
    }

    private var unitTestResultsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Summary
            let passed = testResults.filter { $0.passed }.count
            let total = testResults.count

            HStack {
                Text("Results: \(passed)/\(total) passed")
                    .font(.headline)
                Spacer()
                if passed == total {
                    Label("All Passed", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Label("\(total - passed) Failed", systemImage: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(passed == total ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            .cornerRadius(8)

            // Individual results
            ForEach(Array(testResults.enumerated()), id: \.offset) { _, result in
                HStack {
                    Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.passed ? .green : .red)
                    Text(result.name)
                        .font(.caption)
                    Spacer()
                }
                .padding(.vertical, 4)
            }

            // Re-run button
            Button("Run Again") {
                testResults = []
                runUnitTests()
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.bordered)
        }
    }

    private func runUnitTests() {
        isRunningTests = true
        DispatchQueue.global(qos: .userInitiated).async {
            let results = InsightsEngineTestRunner.runAllTests()
            DispatchQueue.main.async {
                testResults = results
                isRunningTests = false

                // Also print to console for CI/automation
                InsightsEngineTestRunner.printTestResults()
            }
        }
    }

    private var childPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Child")
                .font(.caption)
                .foregroundColor(.secondary)

            Picker("Child", selection: $selectedChildId) {
                Text("Select...").tag(nil as String?)
                ForEach(childrenStore.activeChildren) { child in
                    Text(child.name).tag(child.id.uuidString as String?)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedChildId) { _, newValue in
                if newValue != nil {
                    generateReport()
                }
            }
        }
    }

    private func reportContent(_ report: InsightsDebugReport) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Stats Section
            statsSection(report)

            Divider()

            // Triggered Signals
            triggeredSignalsSection(report)

            Divider()

            // Selected Cards
            selectedCardsSection(report)

            Divider()

            // Cooldowns
            cooldownsSection(report)

            Divider()

            // Not Triggered
            notTriggeredSection(report)

            // Raw Report
            rawReportSection(report)
        }
    }

    private func statsSection(_ report: InsightsDebugReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Data Stats")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                DebugStatBox(label: "Events (14d)", value: "\(report.dataStats.totalEvents14Days)")
                DebugStatBox(label: "Positive (7d)", value: "\(report.dataStats.positiveEvents7Days)")
                DebugStatBox(label: "Challenges (7d)", value: "\(report.dataStats.challengeEvents7Days)")
                DebugStatBox(label: "Routines (7d)", value: "\(report.dataStats.routineEvents7Days)")
                DebugStatBox(label: "Active Goals", value: "\(report.dataStats.activeGoals)")
                DebugStatBox(label: "Routine Types", value: "\(report.dataStats.routineBehaviors)")
            }

            if report.hasInsufficientData {
                Text("Insufficient data for insights")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.top, 4)
            }
        }
    }

    private func triggeredSignalsSection(_ report: InsightsDebugReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Triggered Signals (\(report.triggeredSignals.count))")
                .font(.headline)

            if report.triggeredSignals.isEmpty {
                Text("No signals triggered")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                ForEach(report.triggeredSignals, id: \.signalType) { signal in
                    SignalRow(signal: signal, isTriggered: true)
                }
            }
        }
    }

    private func selectedCardsSection(_ report: InsightsDebugReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected Cards (\(report.selectedCards.count))")
                .font(.headline)

            if report.selectedCards.isEmpty {
                Text("No cards selected")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                ForEach(report.selectedCards, id: \.id) { card in
                    CardRow(card: card)
                }
            }
        }
    }

    private func cooldownsSection(_ report: InsightsDebugReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Cooldowns (\(report.activeCooldowns.count))")
                .font(.headline)

            if report.activeCooldowns.isEmpty {
                Text("No active cooldowns")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                ForEach(report.activeCooldowns, id: \.templateId) { cooldown in
                    HStack {
                        Text(cooldown.templateId)
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                        Text("Ends: \(cooldown.endsAt, style: .relative)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }

    private func notTriggeredSection(_ report: InsightsDebugReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            DisclosureGroup("Not Triggered (\(report.notTriggeredSignals.count))") {
                ForEach(report.notTriggeredSignals, id: \.signalType) { signal in
                    SignalRow(signal: signal, isTriggered: false)
                }
            }
            .font(.headline)
        }
    }

    private func rawReportSection(_ report: InsightsDebugReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            DisclosureGroup("Raw Report") {
                ScrollView(.horizontal) {
                    Text(report.formattedReport())
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
            .font(.headline)
        }
    }

    private func generateReport() {
        guard let childId = selectedChildId else { return }

        isLoading = true
        let dataProvider = RepositoryDataProvider(repository: repository)
        let engine = CoachingEngineImpl(dataProvider: dataProvider)

        // Run on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            let generatedReport = engine.debugReport(childId: childId, now: Date())
            DispatchQueue.main.async {
                self.report = generatedReport
                self.isLoading = false
            }
        }
    }
}

// MARK: - Helper Views

private struct DebugStatBox: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Theme().surface2)
        .cornerRadius(8)
    }
}

private struct SignalRow: View {
    let signal: SignalResult
    let isTriggered: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: isTriggered ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundColor(isTriggered ? .green : .secondary)
                Text(signal.signalType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                if isTriggered {
                    Text("\(Int(signal.confidence * 100))% confidence")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Text(signal.explanation)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)

            if isTriggered {
                Text("Evidence: \(signal.evidence.count) events")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .padding(8)
        .background(isTriggered ? Color.green.opacity(0.1) : Theme().surface2)
        .cornerRadius(8)
    }
}

private struct CardRow: View {
    let card: CoachCard

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(card.title)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Text("P\(card.priority)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(priorityColor)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }

            Text(card.oneLiner)
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack {
                Text(card.templateId)
                    .font(.caption2)
                    .foregroundColor(.blue)
                Spacer()
                Text("\(card.evidenceEventIds.count) events")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }

    private var priorityColor: Color {
        switch card.priority {
        case 5...: return .red
        case 4: return .orange
        case 3: return .yellow
        default: return .gray
        }
    }
}

#Preview {
    InsightsEngineDebugView()
        .environmentObject(Repository.preview)
        .environmentObject(ChildrenStore(repository: Repository.preview))
}
#endif
