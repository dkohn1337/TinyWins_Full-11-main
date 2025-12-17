import SwiftUI

/// View displaying partner's shared reflections (Plus feature)
struct SharedReflectionView: View {
    @EnvironmentObject private var repository: Repository
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    let date: Date

    private var isPlusSubscriber: Bool {
        subscriptionManager.effectiveIsPlusSubscriber
    }

    private var sharedNotes: [ParentNote] {
        repository.getParentNotes(forDay: date)
            .filter { $0.isSharedWithPartner }
    }

    private var myNotes: [ParentNote] {
        repository.getParentNotes(forDay: date)
            .filter { !$0.isSharedWithPartner || $0.loggedByParentId == nil }
    }

    private var partnerNotes: [ParentNote] {
        repository.getParentNotes(forDay: date)
            .filter { $0.isSharedWithPartner && $0.loggedByParentId != nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.teal)
                Text("Partner Reflections")
                    .font(.headline)

                Spacer()

                if isPlusSubscriber {
                    Text("PLUS")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(
                                colors: [.teal, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(4)
                }
            }

            if partnerNotes.isEmpty {
                emptyState
            } else {
                partnerContent
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No shared reflections today")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("When your partner shares their reflections, you'll see them here.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Partner Content

    private var partnerContent: some View {
        VStack(spacing: 12) {
            ForEach(partnerNotes) { note in
                PartnerReflectionCard(note: note)
            }

            // Alignment insight
            alignmentInsightView
        }
    }

    // MARK: - Alignment Insight

    @ViewBuilder
    private var alignmentInsightView: some View {
        let myWins = Set(myNotes.filter { $0.noteType == .parentWin }.map { $0.content })
        let partnerWins = Set(partnerNotes.filter { $0.noteType == .parentWin }.map { $0.content })
        let commonWins = myWins.intersection(partnerWins)

        if !commonWins.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Great alignment!")
                        .font(.caption.weight(.semibold))
                    Text("You both selected \"\(simplifyWin(commonWins.first ?? ""))\" today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(12)
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(10)
        }
    }

    private func simplifyWin(_ text: String) -> String {
        let simplifications: [String: String] = [
            "I stayed calm during a difficult moment": "staying calm",
            "I praised effort instead of just results": "praising effort",
            "I listened without interrupting": "active listening",
            "I gave a genuine hug today": "showing affection",
            "I apologized when I was wrong": "apologizing",
            "I took a breather when I needed one": "taking breaks",
            "I celebrated a small win": "celebrating wins",
            "I was patient when things were hard": "being patient"
        ]
        return simplifications[text] ?? text.lowercased()
    }
}

// MARK: - Partner Reflection Card

private struct PartnerReflectionCard: View {
    let note: ParentNote

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: note.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Partner name
            HStack {
                if let partnerName = note.loggedByParentName {
                    Text(partnerName)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.teal)
                }

                Spacer()

                Text(timeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Content
            Text(note.content)
                .font(.subheadline)

            // Type badge
            HStack {
                if note.noteType == .parentWin {
                    Label("Win", systemImage: "heart.fill")
                        .font(.caption2)
                        .foregroundColor(.pink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.pink.opacity(0.1))
                        .cornerRadius(6)
                } else {
                    Label("Reflection", systemImage: "moon.fill")
                        .font(.caption2)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(6)
                }
            }
        }
        .padding(12)
        .background(Color.teal.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Compact Partner Card (for DailyCheckInView)

struct PartnerReflectionCompactCard: View {
    @EnvironmentObject private var repository: Repository

    let date: Date

    private var partnerNotes: [ParentNote] {
        repository.getParentNotes(forDay: date)
            .filter { $0.isSharedWithPartner && $0.loggedByParentId != nil }
    }

    var body: some View {
        if !partnerNotes.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.teal)
                    Text("From your partner")
                        .font(.subheadline.weight(.medium))

                    Spacer()

                    Text("\(partnerNotes.count) reflection\(partnerNotes.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Preview first note
                if let firstNote = partnerNotes.first {
                    Text(firstNote.content)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(12)
            .background(Color.teal.opacity(0.08))
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview

#Preview {
    let repository = Repository.preview
    SharedReflectionView(date: Date())
        .environmentObject(repository)
        .environmentObject(SubscriptionManager.shared)
        .padding()
}
