import Foundation

struct Family: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String

    // MARK: - Co-Parent Sync Fields (NEW)
    var memberIds: [String]  // Parent Firebase UIDs or local IDs
    var inviteCode: String?  // 6-character invite code for joining
    var inviteCodeExpiresAt: Date?  // When the invite code expires
    var createdAt: Date
    var createdByParentId: String?  // Who created this family

    init(
        id: UUID = UUID(),
        name: String = "My Family",
        memberIds: [String] = [],
        inviteCode: String? = nil,
        inviteCodeExpiresAt: Date? = nil,
        createdAt: Date = Date(),
        createdByParentId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.memberIds = memberIds
        self.inviteCode = inviteCode
        self.inviteCodeExpiresAt = inviteCodeExpiresAt
        self.createdAt = createdAt
        self.createdByParentId = createdByParentId
    }
}

// MARK: - Migration Support

extension Family {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)

        // New optional fields with migration defaults
        memberIds = try container.decodeIfPresent([String].self, forKey: .memberIds) ?? []
        inviteCode = try container.decodeIfPresent(String.self, forKey: .inviteCode)
        inviteCodeExpiresAt = try container.decodeIfPresent(Date.self, forKey: .inviteCodeExpiresAt)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        createdByParentId = try container.decodeIfPresent(String.self, forKey: .createdByParentId)
    }
}

// MARK: - Family Helpers

extension Family {
    /// Number of parents in this family
    var parentCount: Int {
        memberIds.count
    }

    /// Whether this family has a partner (2 parents)
    var hasPartner: Bool {
        memberIds.count >= 2
    }

    /// Whether the invite code is still valid
    var isInviteCodeValid: Bool {
        guard let code = inviteCode, !code.isEmpty else { return false }
        guard let expiresAt = inviteCodeExpiresAt else { return true }  // No expiry = always valid
        return expiresAt > Date()
    }

    /// Add a parent to the family
    mutating func addMember(_ parentId: String) {
        if !memberIds.contains(parentId) {
            memberIds.append(parentId)
        }
    }

    /// Remove a parent from the family
    mutating func removeMember(_ parentId: String) {
        memberIds.removeAll { $0 == parentId }
    }

    /// Generate a new invite code
    mutating func generateInviteCode(validFor days: Int = 7) {
        inviteCode = Family.randomInviteCode()
        inviteCodeExpiresAt = Calendar.current.date(byAdding: .day, value: days, to: Date())
    }

    /// Clear the invite code
    mutating func clearInviteCode() {
        inviteCode = nil
        inviteCodeExpiresAt = nil
    }

    /// Generate a random 6-character invite code
    static func randomInviteCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"  // Excluding confusing chars like 0/O, 1/I
        return String((0..<6).map { _ in characters.randomElement()! })
    }
}

// MARK: - Preview

extension Family {
    static var preview: Family {
        Family(
            name: "The Smiths",
            memberIds: ["parent1-id", "parent2-id"],
            inviteCode: "TW4K9X"
        )
    }
}
