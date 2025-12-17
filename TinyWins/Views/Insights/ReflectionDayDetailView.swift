import SwiftUI

/// Detail view showing all reflections for a specific day
struct ReflectionDayDetailView: View {
    @EnvironmentObject private var repository: Repository
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    let date: Date

    private var notes: [ParentNote] {
        repository.getParentNotes(forDay: date)
    }

    private var parentWins: [ParentNote] {
        notes.filter { $0.noteType == .parentWin }
    }

    private var reflections: [ParentNote] {
        notes.filter { $0.noteType == .reflection || $0.noteType == .goodMoment }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    private var isPlusSubscriber: Bool {
        subscriptionManager.effectiveIsPlusSubscriber
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if notes.isEmpty {
                        emptyState
                    } else {
                        // Parent Wins Section
                        if !parentWins.isEmpty {
                            parentWinsSection
                        }

                        // Custom Notes Section
                        if !reflections.isEmpty {
                            reflectionsSection
                        }

                        // Partner's shared reflection (Plus feature)
                        if isPlusSubscriber {
                            partnerReflectionSection
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(dateString)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No reflection on this day")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Reflecting daily helps you notice patterns and celebrate your wins as a parent.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    // MARK: - Parent Wins Section

    private var parentWinsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                Text("Parent Wins")
                    .font(.headline)
            }

            VStack(spacing: 8) {
                ForEach(parentWins) { win in
                    ParentWinRow(note: win)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Reflections Section

    private var reflectionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.purple)
                Text("Notes")
                    .font(.headline)
            }

            VStack(spacing: 12) {
                ForEach(reflections) { note in
                    ReflectionNoteRow(note: note)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Partner Reflection Section

    @ViewBuilder
    private var partnerReflectionSection: some View {
        let sharedNotes = notes.filter { $0.isSharedWithPartner && $0.loggedByParentId != nil }

        if !sharedNotes.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.teal)
                    Text("Partner's Reflection")
                        .font(.headline)
                }

                VStack(spacing: 12) {
                    ForEach(sharedNotes) { note in
                        PartnerNoteRow(note: note)
                    }
                }

                // Alignment insight
                alignmentInsight(sharedNotes: sharedNotes)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }

    @ViewBuilder
    private func alignmentInsight(sharedNotes: [ParentNote]) -> some View {
        // Find common wins between partners
        let myWinContents = Set(parentWins.map { $0.content })
        let partnerWinContents = Set(sharedNotes.filter { $0.noteType == .parentWin }.map { $0.content })
        let commonWins = myWinContents.intersection(partnerWinContents)

        if !commonWins.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)

                Text("You both selected \"\(commonWins.first ?? "")\" today")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// MARK: - Parent Win Row

private struct ParentWinRow: View {
    let note: ParentNote

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: note.date)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.pink)
                .font(.subheadline)

            VStack(alignment: .leading, spacing: 4) {
                Text(note.content)
                    .font(.subheadline)

                Text(timeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.pink.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Reflection Note Row

private struct ReflectionNoteRow: View {
    let note: ParentNote

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: note.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.content)
                .font(.subheadline)

            HStack {
                if note.noteType == .goodMoment {
                    Label("Good Moment", systemImage: "sun.max.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                } else {
                    Label("Reflection", systemImage: "moon.fill")
                        .font(.caption2)
                        .foregroundColor(.purple)
                }

                Spacer()

                Text(timeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color.purple.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Partner Note Row

private struct PartnerNoteRow: View {
    let note: ParentNote

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: note.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Partner name
            if let partnerName = note.loggedByParentName {
                Text(partnerName)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.teal)
            }

            Text(note.content)
                .font(.subheadline)

            HStack {
                if note.noteType == .parentWin {
                    Label("Win", systemImage: "heart.fill")
                        .font(.caption2)
                        .foregroundColor(.pink)
                } else {
                    Label("Note", systemImage: "note.text")
                        .font(.caption2)
                        .foregroundColor(.purple)
                }

                Spacer()

                Text(timeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color.teal.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Preview

#Preview {
    let repository = Repository.preview
    ReflectionDayDetailView(date: Date())
        .environmentObject(repository)
        .environmentObject(SubscriptionManager.shared)
}
