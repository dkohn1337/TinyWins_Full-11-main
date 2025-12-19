import Foundation
import Combine

/// Store responsible for managing children state and operations.
/// Extracted from FamilyViewModel to provide focused, single-responsibility state management.
///
/// PERFORMANCE: Uses single Snapshot pattern to batch all state updates into one objectWillChange.
/// Precomputes activeChildren and archivedChildren to avoid per-render filtering.
@MainActor
final class ChildrenStore: ObservableObject {

    // MARK: - Snapshot (single publish for all state)

    struct Snapshot: Equatable {
        var children: [Child] = []
        var activeChildren: [Child] = []
        var archivedChildren: [Child] = []
    }

    // MARK: - Dependencies

    private let repository: RepositoryProtocol

    // MARK: - Published State (single snapshot = single objectWillChange)

    @Published private(set) var snapshot = Snapshot()

    // MARK: - Convenience Accessors (no additional publishes)

    var children: [Child] { snapshot.children }
    var activeChildren: [Child] { snapshot.activeChildren }
    var archivedChildren: [Child] { snapshot.archivedChildren }

    /// Whether there are any children (active or archived)
    var hasChildren: Bool { !snapshot.children.isEmpty }

    /// Whether there are any active (non-archived) children
    var hasActiveChildren: Bool { !snapshot.activeChildren.isEmpty }

    // MARK: - Initialization

    init(repository: RepositoryProtocol) {
        self.repository = repository
        loadChildren()
    }

    // MARK: - Data Loading

    /// PERFORMANCE: Single snapshot assignment = single objectWillChange notification
    func loadChildren() {
        #if DEBUG
        FrameStallMonitor.shared.markBlockReason(.storeRecompute)
        defer { FrameStallMonitor.shared.clearBlockReason() }
        #endif

        let allChildren = repository.getChildren()
        snapshot = Snapshot(
            children: allChildren,
            activeChildren: allChildren.filter { !$0.isArchived },
            archivedChildren: allChildren.filter { $0.isArchived }
        )
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
