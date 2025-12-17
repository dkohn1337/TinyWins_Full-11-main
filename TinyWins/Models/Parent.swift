import Foundation

// MARK: - Parent Model

/// Represents a parent/caregiver in the family.
/// Used for co-parent sync and tracking who logged each behavior.
struct Parent: Identifiable, Codable, Equatable {
    let id: String  // Firebase UID or local UUID string
    var displayName: String
    var email: String?
    var familyId: UUID?
    var role: ParentRole
    var avatarEmoji: String
    var createdAt: Date
    var lastActiveAt: Date

    /// Role of the parent in the family
    enum ParentRole: String, Codable, CaseIterable {
        case parent1 = "Parent 1"
        case parent2 = "Parent 2"

        var displayName: String { rawValue }

        var defaultEmoji: String {
            switch self {
            case .parent1: return "👨"
            case .parent2: return "👩"
            }
        }
    }

    init(
        id: String = UUID().uuidString,
        displayName: String,
        email: String? = nil,
        familyId: UUID? = nil,
        role: ParentRole = .parent1,
        avatarEmoji: String? = nil,
        createdAt: Date = Date(),
        lastActiveAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.familyId = familyId
        self.role = role
        self.avatarEmoji = avatarEmoji ?? role.defaultEmoji
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
    }
}

// MARK: - Parent Extensions

extension Parent {
    /// Create a parent from Firebase Auth user
    static func fromAuthUser(id: String, displayName: String?, email: String?, role: ParentRole = .parent1) -> Parent {
        Parent(
            id: id,
            displayName: displayName ?? "Parent",
            email: email,
            role: role
        )
    }

    /// Short display name (first name or first word)
    var shortName: String {
        displayName.components(separatedBy: " ").first ?? displayName
    }

    /// Update last active timestamp
    mutating func markActive() {
        lastActiveAt = Date()
    }

    /// Whether this parent has been active in the last 24 hours
    var isRecentlyActive: Bool {
        let dayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return lastActiveAt > dayAgo
    }
}

// MARK: - Available Avatar Emojis

extension Parent {
    /// List of emoji options for parent avatars
    static let availableAvatars: [String] = [
        "👨", "👩", "🧑", "👴", "👵", "🧓",
        "👨‍🦱", "👩‍🦱", "👨‍🦰", "👩‍🦰",
        "👨‍🦳", "👩‍🦳", "👨‍🦲", "👩‍🦲",
        "🧔", "🧔‍♀️", "👱", "👱‍♀️"
    ]
}

// MARK: - Preview/Testing

extension Parent {
    static var preview: Parent {
        Parent(
            displayName: "Dad",
            email: "dad@example.com",
            role: .parent1,
            avatarEmoji: "👨"
        )
    }

    static var previewPartner: Parent {
        Parent(
            displayName: "Mom",
            email: "mom@example.com",
            role: .parent2,
            avatarEmoji: "👩"
        )
    }
}
