import Foundation

/// Represents a signature on the family agreement
struct AgreementSignature: Codable, Equatable {
    var signatureData: Data? // PNG image data of the drawn signature
    var signedAt: Date?
    
    var isSigned: Bool {
        signatureData != nil && signedAt != nil
    }
}

struct Child: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var age: Int?
    var colorTag: ColorTag
    var activeRewardId: UUID?
    
    // Cached total points - updated when events change
    var totalPoints: Int
    
    // Allowance tracking
    var totalAllowanceEarned: Double
    var allowancePaidOut: Double
    
    // Agreement signatures
    var childSignature: AgreementSignature
    var parentSignature: AgreementSignature
    var agreementVersion: Int // Incremented when agreement content changes
    
    // Archive status
    var isArchived: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        age: Int? = nil,
        colorTag: ColorTag = .blue,
        activeRewardId: UUID? = nil,
        totalPoints: Int = 0,
        totalAllowanceEarned: Double = 0,
        allowancePaidOut: Double = 0,
        childSignature: AgreementSignature = AgreementSignature(),
        parentSignature: AgreementSignature = AgreementSignature(),
        agreementVersion: Int = 1,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.colorTag = colorTag
        self.activeRewardId = activeRewardId
        self.totalPoints = totalPoints
        self.totalAllowanceEarned = totalAllowanceEarned
        self.allowancePaidOut = allowancePaidOut
        self.childSignature = childSignature
        self.parentSignature = parentSignature
        self.agreementVersion = agreementVersion
        self.isArchived = isArchived
    }
}

extension Child {
    var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
    
    /// Available allowance balance (earned minus paid out)
    var allowanceBalance: Double {
        totalAllowanceEarned - allowancePaidOut
    }
    
    /// Formatted allowance balance string
    var formattedAllowanceBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: allowanceBalance)) ?? "$0.00"
    }
    
    /// Age group for behavior suggestions
    var ageGroup: String? {
        guard let age = age else { return nil }
        switch age {
        case 2...4: return "Toddler"
        case 4...6: return "Preschool"
        case 6...8: return "Early Elementary"
        case 8...11: return "Late Elementary"
        case 11...13: return "Tween"
        case 13...18: return "Teen"
        default: return nil
        }
    }
    
    /// Whether the family agreement is fully signed
    var isAgreementSigned: Bool {
        childSignature.isSigned && parentSignature.isSigned
    }
    
    /// The date when the agreement was fully signed (later of the two signatures)
    var agreementSignedDate: Date? {
        guard let childDate = childSignature.signedAt,
              let parentDate = parentSignature.signedAt else {
            return nil
        }
        return max(childDate, parentDate)
    }
}
