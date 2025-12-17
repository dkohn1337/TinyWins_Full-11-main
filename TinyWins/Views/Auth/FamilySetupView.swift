import SwiftUI

// MARK: - FamilySetupView

/// View for creating a new family or joining an existing one.
/// Shown after successful sign-in when user doesn't have a family yet.
struct FamilySetupView: View {
    @Environment(\.themeProvider) private var theme
    @Environment(\.dismiss) private var dismiss

    let currentUser: AuthUser
    let onCreateFamily: (Family, Parent) -> Void
    let onJoinFamily: () -> Void

    @State private var familyName: String = ""
    @State private var parentName: String = ""
    @State private var selectedEmoji: String = "👨"
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Welcome Header
                    welcomeSection

                    // Choice Cards
                    choiceSection

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Family Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Welcome Section

    private var welcomeSection: some View {
        VStack(spacing: 12) {
            Text("Welcome to Tiny Wins!")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundColor(theme.primaryText)

            Text("Let's set up your family so you can start celebrating small wins together.")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Choice Section

    private var choiceSection: some View {
        VStack(spacing: 20) {
            // Create New Family Card
            createFamilyCard

            // Or Divider
            HStack {
                Rectangle()
                    .fill(theme.divider)
                    .frame(height: 1)
                Text("or")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
                    .padding(.horizontal, 12)
                Rectangle()
                    .fill(theme.divider)
                    .frame(height: 1)
            }

            // Join Existing Family Card
            joinFamilyCard
        }
    }

    private var createFamilyCard: some View {
        VStack(spacing: 20) {
            // Card Header
            HStack {
                Image(systemName: "house.fill")
                    .font(.title2)
                    .foregroundColor(theme.accentColor)

                Text("Create a New Family")
                    .font(.headline)
                    .foregroundColor(theme.primaryText)

                Spacer()
            }

            // Family Name Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Family Name")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.secondaryText)

                TextField("e.g., The Smiths", text: $familyName)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
            }

            // Your Name Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Name")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.secondaryText)

                TextField("e.g., Dad, Mom, Papa", text: $parentName)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
            }

            // Avatar Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Avatar")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.secondaryText)

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
                                                  theme.accentColor.opacity(0.2) :
                                                  Color(.systemGray6))
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(selectedEmoji == emoji ?
                                                    theme.accentColor : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                    }
                }
            }

            // Create Button
            Button(action: createFamily) {
                HStack {
                    if isCreating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Create Family")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(canCreate ? theme.accentColor : theme.accentDisabled)
                .cornerRadius(theme.cornerRadius)
            }
            .disabled(!canCreate || isCreating)
        }
        .padding(20)
        .background(theme.cardBackground)
        .cornerRadius(theme.cornerRadius)
        .shadow(color: theme.cardShadow, radius: theme.cardShadowRadius, y: 2)
    }

    private var joinFamilyCard: some View {
        Button(action: onJoinFamily) {
            HStack(spacing: 16) {
                Image(systemName: "person.badge.plus")
                    .font(.title2)
                    .foregroundColor(theme.positiveColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Join an Existing Family")
                        .font(.headline)
                        .foregroundColor(theme.primaryText)

                    Text("Enter an invite code from your partner")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(theme.secondaryText)
            }
            .padding(20)
            .background(theme.cardBackground)
            .cornerRadius(theme.cornerRadius)
            .shadow(color: theme.cardShadow, radius: theme.cardShadowRadius, y: 2)
        }
    }

    // MARK: - Helpers

    private var canCreate: Bool {
        !familyName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !parentName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func createFamily() {
        isCreating = true

        let family = Family(
            name: familyName.trimmingCharacters(in: .whitespaces),
            memberIds: [currentUser.id],
            createdByParentId: currentUser.id
        )

        let parent = Parent(
            id: currentUser.id,
            displayName: parentName.trimmingCharacters(in: .whitespaces),
            email: currentUser.email,
            familyId: family.id,
            role: .parent1,
            avatarEmoji: selectedEmoji
        )

        onCreateFamily(family, parent)
    }
}

// MARK: - Preview

#Preview {
    FamilySetupView(
        currentUser: AuthUser(id: "test-user", displayName: "Test User", email: "test@example.com"),
        onCreateFamily: { family, parent in
            print("Created family: \(family.name) with parent: \(parent.displayName)")
        },
        onJoinFamily: {
            print("Join family tapped")
        }
    )
    .withThemeProvider(ThemeProvider())
}
