import SwiftUI

/// View shown immediately after factory reset completes.
/// Provides reassurance and a clear path forward to set up the first child again.
struct PostResetView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                // Calm checkmark icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                }

                // Reassuring title
                Text("Start fresh with TinyWins")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                // Non-judgmental body copy
                Text("You've cleared your data on this device. Let's set up your first child again.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)

                Spacer()

                // Primary CTA - navigates to Add Child flow
                VStack(spacing: 12) {
                    Button(action: {
                        // Dismiss this sheet first
                        dismiss()
                        // Navigate to Kids tab and open Add Child sheet
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            coordinator.selectTab(.kids)
                            coordinator.showAddChild()
                        }
                    }) {
                        Text("Set up your first child")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }

                    // Secondary option - return to home in clean state
                    Button(action: {
                        dismiss()
                        // Navigate to Today tab
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            coordinator.selectTab(.today)
                        }
                    }) {
                        Text("Back to Home")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    PostResetView()
        .environmentObject(AppCoordinator())
}
