import Foundation
import Combine

/// Store responsible for managing children state and operations.
/// Extracted from FamilyViewModel to provide focused, single-responsibility state management.
@MainActor
final class ChildrenStore: ObservableObject {

    // MARK: - Dependencies

    private let repository: RepositoryProtocol

    // MARK: - Published State

    @Published private(set) var children: [Child] = []

    // MARK: - Computed Properties

    /// Children that are not archived (for Today, Rewards, etc.)
    var activeChildren: [Child] {
        children.filter { !$0.isArchived }
    }

    /// Children that are archived
    var archivedChildren: [Child] {
        children.filter { $0.isArchived }
    }

    /// Whether there are any children (active or archived)
    var hasChildren: Bool {
        !children.isEmpty
    }

    /// Whether there are any active (non-archived) children
    var hasActiveChildren: Bool {
        !activeChildren.isEmpty
    }

    // MARK: - Initialization

    init(repository: RepositoryProtocol) {
        self.repository = repository
        loadChildren()
    }

    // MARK: - Data Loading

    func loadChildren() {
        children = repository.getChildren()
    }

    // MARK: - Child Queries

    func child(id: UUID) -> Child? {
        children.first { $0.id == id }
    }

    // MARK: - CRUD Operations

    func addChild(_ child: Child) {
        repository.addChild(child)
        loadChildren()
    }

    func updateChild(_ child: Child) {
        guard children.contains(where: { $0.id == child.id }) else {
            #if DEBUG
            print("⚠️ ChildrenStore: Attempted to update non-existent child: \(child.id)")
            #endif
            return
        }
        repository.updateChild(child)
        loadChildren()
    }

    func deleteChild(id: UUID) {
        guard children.contains(where: { $0.id == id }) else {
            #if DEBUG
            print("⚠️ ChildrenStore: Attempted to delete non-existent child: \(id)")
            #endif
            return
        }
        repository.deleteChild(id: id)
        loadChildren()
    }

    func archiveChild(id: UUID) {
        guard var child = child(id: id) else { return }
        child.isArchived = true
        repository.updateChild(child)
        loadChildren()
    }

    func unarchiveChild(id: UUID) {
        guard var child = child(id: id) else { return }
        child.isArchived = false
        repository.updateChild(child)
        loadChildren()
    }

    // MARK: - Allowance Methods

    func recordAllowancePayout(childId: UUID, amount: Double) {
        guard var child = child(id: childId) else { return }
        child.allowancePaidOut += amount
        updateChild(child)
    }

    // MARK: - Agreement System (Child Signatures)

    /// Sign the agreement for a child (updates child signature)
    func signAgreement(childId: UUID, signatureType: SignatureType, signatureData: Data) {
        guard var child = child(id: childId) else { return }
        let signature = AgreementSignature(signatureData: signatureData, signedAt: Date())
        switch signatureType {
        case .child:
            child.childSignature = signature
        case .parent:
            child.parentSignature = signature
        }
        repository.updateChild(child)
        loadChildren()
    }

    func clearAgreementSignatures(childId: UUID) {
        guard var child = child(id: childId) else { return }
        child.childSignature = AgreementSignature()
        child.parentSignature = AgreementSignature()
        child.agreementVersion += 1
        repository.updateChild(child)
        loadChildren()
    }
}
