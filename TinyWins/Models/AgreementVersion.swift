import Foundation
import SwiftUI

/// Represents a version of the family agreement that covers specific goals and behaviors
struct AgreementVersion: Identifiable, Codable, Equatable {
 let id: UUID
 let childId: UUID
 var coveredRewardIds: [UUID] // Goals covered by this agreement
 var coveredBehaviorIds: [UUID] // Behaviors included
 var parentSignedAt: Date?
 var childSignedAt: Date?
 let createdAt: Date
 var isCurrent: Bool
 
 // Signature data
 var childSignatureData: Data?
 var parentSignatureData: Data?
 
 // Migration: support old field names
 enum CodingKeys: String, CodingKey {
 case id, childId
 case coveredRewardIds = "rewardIdsIncluded"
 case coveredBehaviorIds = "behaviorIdsIncluded"
 case parentSignedAt = "signedByParentAt"
 case childSignedAt = "signedByChildAt"
 case createdAt, isCurrent
 case childSignatureData, parentSignatureData
 }
 
 init(
 id: UUID = UUID(),
 childId: UUID,
 coveredRewardIds: [UUID] = [],
 coveredBehaviorIds: [UUID] = [],
 parentSignedAt: Date? = nil,
 childSignedAt: Date? = nil,
 createdAt: Date = Date(),
 isCurrent: Bool = true,
 childSignatureData: Data? = nil,
 parentSignatureData: Data? = nil
 ) {
 self.id = id
 self.childId = childId
 self.coveredRewardIds = coveredRewardIds
 self.coveredBehaviorIds = coveredBehaviorIds
 self.parentSignedAt = parentSignedAt
 self.childSignedAt = childSignedAt
 self.createdAt = createdAt
 self.isCurrent = isCurrent
 self.childSignatureData = childSignatureData
 self.parentSignatureData = parentSignatureData
 }
 
 /// Whether this agreement version is fully signed by both parties
 var isFullySigned: Bool {
 parentSignedAt != nil && childSignedAt != nil
 }
 
 /// Whether child has signed
 var isChildSigned: Bool {
 childSignedAt != nil && childSignatureData != nil
 }
 
 /// Whether parent has signed
 var isParentSigned: Bool {
 parentSignedAt != nil && parentSignatureData != nil
 }
 
 /// The date when the agreement was fully signed (later of the two signatures)
 var signedDate: Date? {
 guard let childDate = childSignedAt,
 let parentDate = parentSignedAt else {
 return nil
 }
 return max(childDate, parentDate)
 }
}

// MARK: - Agreement Coverage Status (Single Source of Truth)

/// High-level agreement status used throughout the Agreement tab
enum AgreementCoverageStatus: Equatable {
 case neverSigned // No agreement with both signatures
 case signedCurrent // Has signed agreement and covers current goals
 case signedOutOfDate // Has signed agreement but does not cover current goals
 
 var statusPillText: String {
 switch self {
 case .neverSigned:
 return "Not signed yet"
 case .signedCurrent:
 return "Included in agreement"
 case .signedOutOfDate:
 return "Needs update"
 }
 }
 
 var statusPillColor: Color {
 switch self {
 case .neverSigned:
 return .orange
 case .signedCurrent:
 return Color(red: 0.2, green: 0.7, blue: 0.4) // Green
 case .signedOutOfDate:
 return .orange
 }
 }
 
 var subtext: String {
 switch self {
 case .neverSigned:
 return "Sign your agreement together to get started."
 case .signedCurrent:
 return "Your goals and rules match what you signed together."
 case .signedOutOfDate:
 return "You added new goals. Review and sign again together."
 }
 }
}

// MARK: - Legacy Support (deprecated, use AgreementCoverageStatus instead)

enum AgreementStatus: Equatable {
 case notSignedYet
 case signedAndUpToDate(activeGoalsCount: Int)
 case needsReview(newGoalsCount: Int)
 
 var chipText: String {
 switch self {
 case .notSignedYet:
 return "Not Signed Yet"
 case .signedAndUpToDate(let count):
 return "Signed · \(count) Active \(count == 1 ?"Goal" :"Goals")"
 case .needsReview(let count):
 return "Needs Review · \(count) New \(count == 1 ?"Goal" :"Goals")"
 }
 }
 
 var chipColor: ChipColor {
 switch self {
 case .notSignedYet:
 return .orange
 case .signedAndUpToDate:
 return .green
 case .needsReview:
 return .amber
 }
 }
 
 enum ChipColor {
 case orange, green, amber
 
 var background: Color {
 switch self {
 case .orange: return .orange.opacity(0.15)
 case .green: return Color(red: 0.2, green: 0.7, blue: 0.4).opacity(0.15)
 case .amber: return .yellow.opacity(0.2)
 }
 }
 
 var foreground: Color {
 switch self {
 case .orange: return .orange
 case .green: return Color(red: 0.2, green: 0.7, blue: 0.4)
 case .amber: return .orange
 }
 }
 }
}
