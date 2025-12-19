import SwiftUI

// MARK: - JoinFamilyView

/// View for joining an existing family using an invite code.
struct JoinFamilyView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    let currentUser: AuthUser
    let onJoinFamily: (String, Parent) -> Void

    @State private var inviteCode: String = ""
    @State private var parentName: String = ""
    @State private var selectedEmoji: String = "👩"
    @State private var isJoining = false
    @State private var errorMessage: String?

    @FocusState private var isCodeFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Instructions Header
                    instructionsSection

                    // Invite Code Input
                    inviteCodeSection

                    // Parent Details
                    parentDetailsSection

                    // Join Button
                    joinButton

                    // How to get code
                    helpSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .background(theme.bg0.ignoresSafeArea())
            .navigationTitle("Join Family")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Join Failed", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear {
                isCodeFocused = true
            }
        }
    }

    // MARK: - Instructions Section

    private var instructionsSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "ticket.fill")
                .font(.system(size: 48))
                .foregroundColor(theme.accentPrimary)

            Text("Enter Invite Code")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundColor(theme.textPrimary)

            Text("Ask your partner for the 6-character invite code from their Tiny Wins app")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Invite Code Section

    private var inviteCodeSection: some View {
        VStack(spacing: 12) {
            // Code Input
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    codeCharacterBox(at: index)
                }
            }

            // Hidden text field for actual input
            TextField("", text: $inviteCode)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .focused($isCodeFocused)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: inviteCode) { _, newValue in
                    // Limit to 6 characters, uppercase
                    let filtered = String(newValue.uppercased().prefix(6))
                        .filter { $0.isLetter || $0.isNumber }
                    if filtered != inviteCode {
                        inviteCode = filtered
                    }
                }
        }
        .onTapGesture {
            isCodeFocused = true
        }
    }

    private func codeCharacterBox(at index: Int) -> some View {
        let characters = Array(inviteCode)
        let character = index < characters.count ? String(characters[index]) : ""

        return Text(character)
            .font(.system(size: 28, weight: .bold, design: .monospaced))
            .foregroundColor(theme.textPrimary)
            .frame(width: 48, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.surface1)
                    .shadow(color: theme.shadowColor.opacity(theme.shadowStrength), radius: 4, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        index == inviteCode.count && isCodeFocused ?
                        theme.accentPrimary : theme.borderSoft,
                        lineWidth: index == inviteCode.count && isCodeFocused ? 2 : 1
                    )
            )
    }

    // MARK: - Parent Details Section

    private var parentDetailsSection: some View {
        VStack(spacing: 20) {
            // Your Name Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Name")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textSecondary)

                TextField("e.g., Mom, Dad, Papa", text: $parentName)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
            }

            // Avatar Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Avatar")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textSecondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Parent.availableAvatars, id: \.self) { emoji in
                            Button {
                                selectedEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 32))
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Circle()
                                            .fill(selectedEmoji == emoji ?
                                                  theme.accentPrimary.opacity(0.2) :
                                                  theme.surface2)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(selectedEmoji == emoji ?
                                                    theme.accentPrimary : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(theme.surface1)
        .cornerRadius(12)
        .shadow(color: theme.shadowColor.opacity(theme.shadowStrength), radius: 8, y: 2)
    }

    // MARK: - Join Button

    private var joinButton: some View {
        Button(action: joinFamily) {
            HStack {
                if isJoining {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Join Family")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(canJoin ? theme.accentPrimary : theme.accentPrimary.opacity(0.5))
            .cornerRadius(12)
        }
        .disabled(!canJoin || isJoining)
    }

    // MARK: - Help Section

    private var helpSection: some View {
        VStack(spacing: 12) {
            Text("How to get an invite code")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(theme.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                helpStep(number: 1, text: "Your partner opens Tiny Wins")
                helpStep(number: 2, text: "Goes to Settings > Co-Parent Sync")
                helpStep(number: 3, text: "Taps \"Invite Partner\" to get the code")
            }
        }
        .padding(16)
        .background(theme.surface2)
        .cornerRadius(12)
    }

    private func helpStep(number: Int, text: String) -> some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(theme.accentPrimary))

            Text(text)
                .font(.caption)
                .foregroundColor(theme.textSecondary)

            Spacer()
        }
    }

    // MARK: - Helpers

    private var canJoin: Bool {
        inviteCode.count == 6 &&
        !parentName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func joinFamily() {
        isJoining = true
        errorMessage = nil

        let parent = Parent(
            id: currentUser.id,
            displayName: parentName.trimmingCharacters(in: .whitespaces),
            email: currentUser.email,
            role: .parent2,
            avatarEmoji: selectedEmoji
        )

        // The actual join logic will be handled by the parent view
        // which has access to FirebaseSyncBackend
        onJoinFamily(inviteCode.uppercased(), parent)
    }
}

// MARK: - Preview

#Preview {
    JoinFamilyView(
        currentUser: AuthUser(id: "test-user", displayName: "Test User", email: "test@example.com"),
        onJoinFamily: { code, parent in
            print("Joining with code: \(code), parent: \(parent.displayName)")
        }
    )
    .withTheme(Theme())
}
