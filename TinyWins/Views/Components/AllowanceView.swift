import SwiftUI

struct AllowanceView: View {
    @EnvironmentObject private var repository: Repository
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @EnvironmentObject private var userPreferences: UserPreferencesStore
    @State private var showingPayoutSheet = false
    @State private var selectedChild: Child?

    private var allowanceSettings: AllowanceSettings {
        repository.getAllowanceSettings()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Total Family Allowance Summary
                    totalSummaryCard
                    
                    // Per-child Allowance
                    ForEach(childrenStore.children) { child in
                        ChildAllowanceCard(child: child) {
                            selectedChild = child
                            showingPayoutSheet = true
                        }
                    }
                    
                    // Behaviors with Allowance Values
                    behaviorsWithAllowanceSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Allowance")
            .sheet(isPresented: $showingPayoutSheet) {
                if let child = selectedChild {
                    PayoutSheet(child: child)
                }
            }
        }
    }
    
    // MARK: - Total Summary Card

    private var totalSummaryCard: some View {
        let totalEarned = childrenStore.children.reduce(0.0) { $0 + behaviorsStore.allowanceEarned(forChild: $1.id, period: nil, allowanceSettings: allowanceSettings) }
        let totalPaid = childrenStore.children.reduce(0.0) { $0 + $1.allowancePaidOut }
        let totalBalance = totalEarned - totalPaid
        
        return VStack(spacing: 16) {
            HStack {
                Image(systemName: "banknote.fill")
                    .font(.title)
                    .foregroundColor(.green)
                
                Text("Family Allowance")
                    .font(.headline)
                
                Spacer()

                if !allowanceSettings.isEnabled {
                    Text("Disabled")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }
            }

            if allowanceSettings.isEnabled {
                HStack(spacing: 20) {
                    VStack {
                        Text(allowanceSettings.formatMoney(totalEarned))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("Earned")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    VStack {
                        Text(allowanceSettings.formatMoney(totalPaid))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("Paid Out")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    VStack {
                        Text(allowanceSettings.formatMoney(totalBalance))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Text("Balance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                Text("Enable allowance in Settings to track earnings")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Behaviors with Allowance

    private var behaviorsWithAllowanceSection: some View {
        let monetizedBehaviors = behaviorsStore.behaviorTypes.filter { $0.isMonetized && $0.isActive && $0.defaultPoints > 0 }
        
        return Group {
            if !monetizedBehaviors.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Monetized Behaviors")
                            .font(.headline)
                        
                        Spacer()

                        if allowanceSettings.isEnabled {
                            Text("\(Int(allowanceSettings.pointsPerUnitCurrency)) pts = \(allowanceSettings.currencySymbol)1")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    ForEach(monetizedBehaviors) { behavior in
                        HStack {
                            Image(systemName: behavior.iconName)
                                .foregroundColor(behaviorColor(for: behavior.category))
                                .frame(width: 24)
                            
                            Text(behavior.name)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("+\(behavior.defaultPoints) pts")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if allowanceSettings.isEnabled {
                                Text(allowanceSettings.formatMoney(allowanceSettings.pointsToMoney(behavior.defaultPoints)))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No Monetized Behaviors")
                        .font(.headline)
                    
                    Text("Mark behaviors as 'Counts for Allowance' in the Manage Behaviors section")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(16)
            }
        }
    }
    
    private func behaviorColor(for category: BehaviorCategory) -> Color {
        switch category {
        case .routinePositive: return .blue
        case .positive: return .green
        case .negative: return .orange
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - Child Allowance Card

struct ChildAllowanceCard: View {
    @EnvironmentObject private var repository: Repository
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    let child: Child
    let onPayout: () -> Void

    private var currentChild: Child {
        childrenStore.child(id: child.id) ?? child
    }

    private var allowanceSettings: AllowanceSettings {
        repository.getAllowanceSettings()
    }

    private var earned: Double {
        behaviorsStore.allowanceEarned(forChild: child.id, period: nil, allowanceSettings: allowanceSettings)
    }
    
    private var balance: Double {
        earned - currentChild.allowancePaidOut
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                ChildAvatar(child: currentChild, size: 40)
                
                VStack(alignment: .leading) {
                    Text(currentChild.name)
                        .font(.headline)
                    
                    Text("Balance: \(formatCurrency(balance))")
                        .font(.subheadline)
                        .foregroundColor(balance > 0 ? .green : .secondary)
                }
                
                Spacer()
                
                Button(action: onPayout) {
                    Text("Pay Out")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(balance > 0 ? currentChild.colorTag.color : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(balance <= 0)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Earned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(earned))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Paid Out")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(currentChild.allowancePaidOut))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        allowanceSettings.formatMoney(amount)
    }
}

// MARK: - Payout Sheet

struct PayoutSheet: View {
    @EnvironmentObject private var repository: Repository
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @Environment(\.dismiss) private var dismiss

    let child: Child

    @State private var payoutAmount: String = ""
    @State private var payFullBalance = true

    private var currentChild: Child {
        childrenStore.child(id: child.id) ?? child
    }

    private var allowanceSettings: AllowanceSettings {
        repository.getAllowanceSettings()
    }

    private var earned: Double {
        behaviorsStore.allowanceEarned(forChild: child.id, period: nil, allowanceSettings: allowanceSettings)
    }
    
    private var balance: Double {
        earned - currentChild.allowancePaidOut
    }
    
    private var amount: Double {
        if payFullBalance {
            return balance
        }
        return Double(payoutAmount) ?? 0
    }
    
    private var isValid: Bool {
        amount > 0 && amount <= balance
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Current Balance")
                        Spacer()
                        Text(allowanceSettings.formatMoney(balance))
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }

                Section {
                    Toggle("Pay Full Balance", isOn: $payFullBalance)

                    if !payFullBalance {
                        HStack {
                            Text(allowanceSettings.currencySymbol)
                            TextField("Amount", text: $payoutAmount)
                                .keyboardType(.decimalPad)
                        }
                    }
                }

                Section {
                    HStack {
                        Text("Payout Amount")
                        Spacer()
                        Text(allowanceSettings.formatMoney(amount))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Pay Out to \(child.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        childrenStore.recordAllowancePayout(childId: child.id, amount: amount)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let repository = Repository.preview
    AllowanceView()
        .environmentObject(repository)
        .environmentObject(ChildrenStore(repository: repository))
        .environmentObject(BehaviorsStore(repository: repository))
        .environmentObject(UserPreferencesStore())
}
