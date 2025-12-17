import SwiftUI
import MessageUI

// MARK: - Feedback Category

enum FeedbackCategory: String, CaseIterable, Identifiable {
    case general = "general"
    case featureIdea = "feature"
    case bug = "bug"
    case question = "question"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "bubble.left.fill"
        case .featureIdea: return "lightbulb.fill"
        case .bug: return "ladybug.fill"
        case .question: return "questionmark.circle.fill"
        }
    }

    var label: String {
        switch self {
        case .general: return "General"
        case .featureIdea: return "Idea"
        case .bug: return "Bug"
        case .question: return "Question"
        }
    }

    var color: Color {
        switch self {
        case .general: return .blue
        case .featureIdea: return .orange
        case .bug: return .red
        case .question: return .purple
        }
    }

    /// Whether this category should show the "What's going well" field
    var showsGoingWell: Bool {
        self == .general
    }

    /// Title for the main input field
    var mainFieldTitle: String {
        switch self {
        case .general: return "Ideas for improvement"
        case .featureIdea: return "Your idea"
        case .bug: return "What went wrong"
        case .question: return "Your question"
        }
    }

    /// Placeholder for the main input field
    var mainFieldPlaceholder: String {
        switch self {
        case .general: return "What could be better or is getting in the way?"
        case .featureIdea: return "Describe the feature you'd love to see..."
        case .bug: return "What happened? What did you expect instead?"
        case .question: return "What would you like to know?"
        }
    }

    var emailSubject: String {
        switch self {
        case .general: return "Tiny Wins feedback"
        case .featureIdea: return "Tiny Wins feature idea"
        case .bug: return "Tiny Wins bug report"
        case .question: return "Tiny Wins question"
        }
    }
}

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var selectedCategory: FeedbackCategory = .general
    @State private var whatIsGoingWell: String = ""
    @State private var whatIsConfusing: String = ""
    @State private var allowFollowUp: Bool = true

    // UI state
    @State private var showingMailComposer = false
    @State private var showingMailNotAvailableAlert = false
    @State private var showingCopiedToast = false
    @State private var showingSentConfirmation = false

    // Pre-fill content (from prompt)
    var prefillGoingWell: String? = nil
    var prefillConfusing: String? = nil

    // Placeholders
    private let goingWellPlaceholder = "Tell us what you like or what feels helpful."
    private let confusingPlaceholder = "Tell us what is not clear, missing, or getting in the way."

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Header
                    feedbackHeader

                    // Form Sections
                    VStack(spacing: 20) {
                        // Category picker
                        categoryPickerSection

                        // What is going well section (only for General feedback)
                        if selectedCategory.showsGoingWell {
                            FeedbackInputSection(
                                icon: "hand.thumbsup.fill",
                                iconGradient: [.green, .mint],
                                title: "What's going well",
                                placeholder: goingWellPlaceholder,
                                text: $whatIsGoingWell
                            )
                        }

                        // Main input section (contextual based on category)
                        FeedbackInputSection(
                            icon: selectedCategory.icon,
                            iconGradient: [selectedCategory.color, selectedCategory.color.opacity(0.7)],
                            title: selectedCategory.mainFieldTitle,
                            placeholder: selectedCategory.mainFieldPlaceholder,
                            text: $whatIsConfusing
                        )

                        // Follow-up toggle
                        followUpSection
                    }
                    .padding(.horizontal, 16)
                    .animation(.easeInOut(duration: 0.2), value: selectedCategory)

                    // Action Buttons
                    VStack(spacing: 12) {
                        // Send button
                        Button(action: sendFeedback) {
                            HStack(spacing: 10) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Send Feedback")
                                    .font(.system(size: 17, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.primary.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .shadow(color: AppColors.primary.opacity(0.3), radius: 8, y: 4)
                        }

                        // Copy fallback button
                        Button(action: copyToClipboard) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.on.clipboard")
                                    .font(.system(size: 14))
                                Text("Copy to clipboard instead")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
                .padding(.top, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Help & Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingMailComposer) {
                MailComposerView(
                    recipients: [FeedbackConfig.supportEmail],
                    subject: selectedCategory.emailSubject,
                    body: buildEmailBody(),
                    onResult: handleMailResult
                )
            }
            .alert("Mail is not set up", isPresented: $showingMailNotAvailableAlert) {
                Button("OK") { }
            } message: {
                Text("We could not open the Mail app on this device. We copied your feedback so you can paste it into any app.")
            }
            .toast(isShowing: $showingCopiedToast, message: "Feedback copied. You can paste it into any app.", icon: "doc.on.clipboard.fill", category: .positive)
            .toast(isShowing: $showingSentConfirmation, message: "Thank you for your feedback.", icon: "checkmark.circle.fill", category: .positive)
            .onAppear {
                if let prefill = prefillGoingWell, whatIsGoingWell.isEmpty {
                    whatIsGoingWell = prefill
                }
                if let prefill = prefillConfusing, whatIsConfusing.isEmpty {
                    whatIsConfusing = prefill
                }
            }
        }
    }

    // MARK: - Category Input Title

    private var categoryInputTitle: String {
        switch selectedCategory {
        case .general: return "Ideas for improvement"
        case .featureIdea: return "Your idea"
        case .bug: return "What went wrong"
        case .question: return "Your question"
        }
    }

    // MARK: - Category Picker Section

    private var categoryPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 32, height: 32)

                    Image(systemName: "tag.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }

                Text("What's this about?")
                    .font(.system(size: 15, weight: .semibold))
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(FeedbackCategory.allCases) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - Feedback Header

    private var feedbackHeader: some View {
        VStack(spacing: 16) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary.opacity(0.2), AppColors.primary.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.primary.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("We'd love to hear from you")
                    .font(.system(size: 20, weight: .bold))

                Text("Your feedback helps us make Tiny Wins better for families like yours.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Follow-up Section

    private var followUpSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 42, height: 42)

                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("OK to follow up")
                        .font(.system(size: 16, weight: .medium))

                    Text("We may reach out to learn more")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: $allowFollowUp)
                    .labelsHidden()
                    .tint(AppColors.primary)
            }
            .padding(14)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
    
    // MARK: - Actions
    
    private func sendFeedback() {
        if MFMailComposeViewController.canSendMail() {
            showingMailComposer = true
        } else {
            copyToClipboard()
            showingMailNotAvailableAlert = true
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = buildEmailBody()
        showingCopiedToast = true
    }
    
    private func handleMailResult(_ result: MFMailComposeResult) {
        switch result {
        case .sent:
            showingSentConfirmation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        case .cancelled, .saved, .failed:
            // Keep view open for user to try again or copy
            break
        @unknown default:
            break
        }
    }
    
    // MARK: - Email Body

    private func buildEmailBody() -> String {
        let goingWellText = whatIsGoingWell.trimmingCharacters(in: .whitespacesAndNewlines)
        let confusingText = whatIsConfusing.trimmingCharacters(in: .whitespacesAndNewlines)

        let deviceInfo = DeviceInfo.current

        return """
        \(selectedCategory.emailSubject)

        Category: \(selectedCategory.label)

        What is going well:
        \(goingWellText.isEmpty ? "Not provided" : goingWellText)

        \(categoryInputTitle):
        \(confusingText.isEmpty ? "Not provided" : confusingText)

        Ok to follow up by email:
        \(allowFollowUp ? "Yes" : "No")

        Context:
        App version: \(deviceInfo.appVersion)
        Build number: \(deviceInfo.buildNumber)
        Device: \(deviceInfo.deviceModel)
        iOS: \(deviceInfo.systemVersion)
        """
    }
}

// MARK: - Category Chip

private struct CategoryChip: View {
    let category: FeedbackCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 13))
                Text(category.label)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? category.color.opacity(0.15) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? category.color : Color.clear, lineWidth: 1.5)
            )
            .foregroundColor(isSelected ? category.color : .secondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Feedback Input Section

private struct FeedbackInputSection: View {
    let icon: String
    let iconGradient: [Color]
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: iconGradient.map { $0.opacity(0.2) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(
                            LinearGradient(colors: iconGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }

            // Text Editor
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                }

                TextEditor(text: $text)
                    .font(.system(size: 15))
                    .frame(minHeight: 100)
                    .padding(10)
                    .scrollContentBackground(.hidden)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

// MARK: - Feedback Config

private enum FeedbackConfig {
    static let supportEmail = "tinywins89@gmail.com"
}

// MARK: - Device Info

private struct DeviceInfo {
    let appVersion: String
    let buildNumber: String
    let deviceModel: String
    let systemVersion: String
    
    static var current: DeviceInfo {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        
        return DeviceInfo(
            appVersion: appVersion,
            buildNumber: buildNumber,
            deviceModel: deviceModel,
            systemVersion: systemVersion
        )
    }
}

// MARK: - Mail Composer View

struct MailComposerView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let body: String
    let onResult: (MFMailComposeResult) -> Void
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients(recipients)
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onResult: (MFMailComposeResult) -> Void
        
        init(onResult: @escaping (MFMailComposeResult) -> Void) {
            self.onResult = onResult
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true) {
                self.onResult(result)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FeedbackView()
}
