import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject private var repository: Repository
    @EnvironmentObject private var childrenStore: ChildrenStore
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @EnvironmentObject private var userPreferences: UserPreferencesStore
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var featureFlags: FeatureFlags
    @EnvironmentObject private var themeProvider: ThemeProvider
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @State private var showingAllowanceSettings = false
    @State private var showingAbout = false
    @State private var showingHowItWorks = false
    @State private var showingEraseDataAlert = false
    @State private var showingEraseConfirmation = false
    @State private var showingPostReset = false
    @State private var showingPaywall = false
    @State private var eraseConfirmationText = ""
    @State private var showingAppearance = false
    @State private var showingNotifications = false
    @State private var showingCoParentSettings = false
    @State private var isErasingData = false
    @State private var showingOnboarding = false
    @State private var showingFeedback = false
    @State private var showingFAQ = false
    @State private var showingHelpCenter = false
    @State private var showingChangelog = false
    @State private var showingShareSheet = false
    @State private var showingExportSheet = false
    @State private var exportFileURL: URL?
    @State private var isExporting = false
    @State private var exportError: String?
    @State private var showingDemoDataAlert = false
    @State private var isLoadingDemoData = false
    @State private var showingEditFamilyName = false
    @State private var editedFamilyName = ""
    @State private var searchText = ""
    @State private var showingHelpTip: String? = nil

    /// Settings items for search filtering
    private var allSettingsItems: [(title: String, section: String, keywords: [String])] {
        [
            ("Appearance", "Preferences", ["theme", "dark mode", "light", "color"]),
            ("Notifications", "Preferences", ["alerts", "reminders", "push"]),
            ("Co-Parent", "Preferences", ["partner", "share", "family"]),
            ("Allowance", "Preferences", ["stars", "points", "money"]),
            ("Family Name", "Family", ["household", "rename"]),
            ("Export Data", "Family", ["backup", "download", "save"]),
            ("Help Center", "Help", ["tutorial", "guide", "learn", "faq", "questions", "support"]),
            ("Contact Us", "Help", ["feedback", "contact", "report", "suggest", "bug"]),
            ("Privacy Policy", "Legal", ["data", "information"]),
            ("Terms of Service", "Legal", ["agreement", "rules"]),
        ]
    }

    /// Filtered settings based on search
    private var matchesSearch: Bool {
        searchText.isEmpty
    }

    private func itemMatchesSearch(_ item: (title: String, section: String, keywords: [String])) -> Bool {
        if searchText.isEmpty { return true }
        let lowercasedSearch = searchText.lowercased()
        return item.title.lowercased().contains(lowercasedSearch) ||
               item.section.lowercased().contains(lowercasedSearch) ||
               item.keywords.contains { $0.contains(lowercasedSearch) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search settings...", text: $searchText)
                            .textFieldStyle(.plain)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Search results hint
                    if !searchText.isEmpty {
                        let matchCount = allSettingsItems.filter { itemMatchesSearch($0) }.count
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("\(matchCount) setting\(matchCount == 1 ? "" : "s") found")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                    }

                    // Account Section (sign in / account management)
                    if searchText.isEmpty {
                        AccountSettingsSection()
                    }

                    // Quick Actions Section (most common tasks)
                    if searchText.isEmpty {
                        quickActionsSection
                    }

                    // Tip of the Day
                    if searchText.isEmpty {
                        tipOfTheDay
                    }

                    // Subscription Status Card
                    if searchText.isEmpty {
                        subscriptionCard
                    }

                    // Preferences Section
                    if searchText.isEmpty || allSettingsItems.filter({ $0.section == "Preferences" }).contains(where: { itemMatchesSearch($0) }) {
                        preferencesSection
                    }

                    // Family & Data Section
                    if searchText.isEmpty || allSettingsItems.filter({ $0.section == "Family" }).contains(where: { itemMatchesSearch($0) }) {
                        familyDataSection
                    }

                    // Help & Support Section
                    if searchText.isEmpty || allSettingsItems.filter({ $0.section == "Help" }).contains(where: { itemMatchesSearch($0) }) {
                        helpSupportSection
                    }

                    // Connect Section
                    if searchText.isEmpty {
                        connectSection
                    }

                    // Privacy & Legal Section
                    if searchText.isEmpty || allSettingsItems.filter({ $0.section == "Legal" }).contains(where: { itemMatchesSearch($0) }) {
                        privacyLegalSection
                    }

                    // Developer Section (controlled by DeveloperConfig)
                    if DeveloperConfig.shouldShowDeveloperSection && searchText.isEmpty {
                        developerSection
                    }

                    // Danger Zone
                    if searchText.isEmpty {
                        dangerZoneSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .background(themeProvider.backgroundColor)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .themedNavigationBar(themeProvider)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAppearance) {
                AppearanceSettingsView()
            }
            .sheet(isPresented: $showingNotifications) {
                NotificationsSettingsView()
            }
            .sheet(isPresented: $showingCoParentSettings) {
                CoParentSettingsView()
            }
            .sheet(isPresented: $showingAllowanceSettings) {
                AllowanceSettingsView()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingHowItWorks) {
                HowItWorksView()
            }
            .sheet(isPresented: $showingPaywall) {
                PlusPaywallView()
            }
            .alert("Erase all data?", isPresented: $showingEraseDataAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Erase all data", role: .destructive) {
                    showingEraseConfirmation = true
                }
            } message: {
                Text("This will permanently delete all children, goals, and moments from this device AND cloud storage. All co-parents will also lose access to this data. This cannot be undone.")
            }
            .alert("Load Demo Data?", isPresented: $showingDemoDataAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Load Demo Data", role: .destructive) {
                    loadDemoData()
                }
            } message: {
                Text("This will replace ALL your current data with demo data:\n\n• 4 children (Emma, Jake, Mia, Lucas)\n• 2 parents (co-parenting demo)\n• 45 days of behavior history\n• Multiple goals at various stages\n• Signed agreements\n• Allowance enabled\n\nYour existing data will be permanently deleted.")
            }
            .alert("Edit Family Name", isPresented: $showingEditFamilyName) {
                TextField("Family Name", text: $editedFamilyName)
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    saveFamilyName()
                }
            } message: {
                Text("Enter a name for your family (e.g., The Smiths)")
            }
            .sheet(isPresented: $showingEraseConfirmation) {
                EraseDataConfirmationView(
                    onConfirm: {
                        performFullDataErase()
                    },
                    onCancel: {
                        showingEraseConfirmation = false
                    }
                )
                .presentationDetents([.medium])
            }
            .fullScreenCover(isPresented: $showingOnboarding) {
                OnboardingFlowView()
            }
            .sheet(isPresented: $showingFeedback) {
                FeedbackView()
            }
            .sheet(isPresented: $showingFAQ) {
                FAQView()
            }
            .sheet(isPresented: $showingHelpCenter) {
                HelpCenterView()
            }
            .sheet(isPresented: $showingChangelog) {
                ChangelogView()
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [
                    "I'm using Tiny Wins to celebrate my kids' small victories! Check it out:",
                    URL(string: AppLinks.appStoreURL)!
                ])
            }
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick Actions")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()

                Text("Common tasks")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .padding(.leading, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    SettingsQuickActionButton(
                        icon: "plus.circle.fill",
                        title: "Log Moment",
                        gradient: [.green, .mint]
                    ) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            // Navigate to Today tab where user can add moments
                            coordinator.selectedTab = .today
                        }
                    }

                    SettingsQuickActionButton(
                        icon: "gift.fill",
                        title: "Set Goal",
                        gradient: [.purple, .pink]
                    ) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            coordinator.selectedTab = .rewards
                        }
                    }

                    SettingsQuickActionButton(
                        icon: "person.badge.plus",
                        title: "Add Child",
                        gradient: [.blue, .cyan]
                    ) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            coordinator.presentSheet(.addChild)
                        }
                    }

                    SettingsQuickActionButton(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Insights",
                        gradient: [.orange, .yellow]
                    ) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            coordinator.selectedTab = .insights
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Tip of the Day

    private var tipOfTheDay: some View {
        let tips: [(icon: String, title: String, message: String, gradient: [Color])] = [
            ("lightbulb.fill", "Catch them being good", "Look for small positive moments, not just big achievements. A quiet 'thank you' counts!", [.yellow, .orange]),
            ("clock.fill", "Consistency wins", "Logging even one moment per day builds powerful habits over time.", [.blue, .cyan]),
            ("heart.fill", "Celebrate effort", "Praise the trying, not just the succeeding. Growth mindset starts here.", [.pink, .red]),
            ("sparkles", "Keep goals achievable", "Start with goals they can reach in a few days. Quick wins build momentum.", [.purple, .indigo]),
            ("star.fill", "Make it visual", "Show your child their star progress. Kids love seeing their achievements grow.", [.yellow, .orange]),
            ("figure.2.and.child.holdinghands", "Involve them", "Let kids help pick their own rewards. Ownership increases motivation.", [.green, .mint]),
            ("moon.stars.fill", "Evening reflections", "End-of-day check-ins help you notice patterns you might have missed.", [.indigo, .purple])
        ]

        // Pick a tip based on the day of year for daily rotation
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let tip = tips[dayOfYear % tips.count]

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: tip.gradient.map { $0.opacity(0.2) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: tip.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(
                            LinearGradient(colors: tip.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Tip of the Day")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    Text(tip.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                }

                Spacer()
            }

            Text(tip.message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeProvider.resolved.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: tip.gradient.map { $0.opacity(0.3) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Subscription Card

    private var subscriptionCard: some View {
        Group {
            if subscriptionManager.effectiveIsPlusSubscriber {
                // Plus subscriber card
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)

                            Image(systemName: "crown.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text("TinyWins Plus")
                                    .font(.system(size: 18, weight: .bold))

                                PlusBadge(small: true)
                            }

                            Text("All features unlocked")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(
                                LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom)
                            )
                    }

                    // Manage Subscription button - Required by Apple
                    Button {
                        openSubscriptionManagement()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "gear")
                                .font(.system(size: 13))
                            Text("Manage Subscription")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.purple)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.1), .pink.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .pink.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            } else {
                // Upgrade CTA
                Button(action: { showingPaywall = true }) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple.opacity(0.2), .pink.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)

                            Image(systemName: "sparkles")
                                .font(.system(size: 24))
                                .foregroundStyle(
                                    LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Get TinyWins+")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.primary)

                            Text("More kids, deeper insights, safe backups")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.purple)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(themeProvider.resolved.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(themeProvider.resolved.cardBorderColor, lineWidth: themeProvider.resolved.cardBorderWidth)
                    )
                    .shadow(color: .purple.opacity(themeProvider.resolved.isDark ? 0.3 : 0.15), radius: 12, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preferences")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                EnhancedSettingsButton(
                    icon: "paintbrush.fill",
                    iconGradient: [.purple, .pink],
                    title: "Appearance",
                    subtitle: "Theme and colors"
                ) {
                    showingAppearance = true
                }

                Divider().padding(.leading, 60)

                EnhancedSettingsButton(
                    icon: "bell.fill",
                    iconGradient: [.red, .orange],
                    title: "Notifications",
                    subtitle: "Reminders and alerts"
                ) {
                    showingNotifications = true
                }

                Divider().padding(.leading, 60)

                EnhancedSettingsButton(
                    icon: "dollarsign.circle.fill",
                    iconGradient: [.green, .mint],
                    title: "Allowance",
                    subtitle: repository.getAllowanceSettings().isEnabled ? "Enabled" : "Disabled",
                    showPlusBadge: true
                ) {
                    showingAllowanceSettings = true
                }

                // Co-Parent Sync (only shown when Firebase is enabled)
                if AppConfiguration.showCoParentFeatures {
                    Divider().padding(.leading, 60)

                    EnhancedSettingsButton(
                        icon: "person.2.fill",
                        iconGradient: [.blue, .cyan],
                        title: "Co-Parent Sync",
                        subtitle: AppConfiguration.isSignedIn ? "Connected" : "Set up sync",
                        showPlusBadge: true
                    ) {
                        showingCoParentSettings = true
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeProvider.resolved.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(themeProvider.resolved.cardBorderColor, lineWidth: themeProvider.resolved.cardBorderWidth)
            )
            .shadow(color: themeProvider.resolved.shadowColor.opacity(themeProvider.resolved.isDark ? 0.3 : 0.04), radius: 8, y: 2)

            // Backup & Sync - REMOVED: iCloud backup feature deprecated
        }
    }

    // MARK: - Family & Data Section

    private var familyDataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Family & Data")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                Button(action: {
                    editedFamilyName = repository.getFamily().name
                    showingEditFamilyName = true
                }) {
                    HStack {
                        EnhancedSettingsInfoRow(
                            icon: "house.fill",
                            iconColor: .blue,
                            title: "Family Name",
                            value: repository.getFamily().name
                        )
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.trailing, 16)
                    }
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 60)

                EnhancedSettingsInfoRow(
                    icon: "figure.2.and.child.holdinghands",
                    iconColor: .purple,
                    title: "Children",
                    value: "\(childrenStore.children.count)"
                )

                Divider().padding(.leading, 60)

                EnhancedSettingsInfoRow(
                    icon: "star.fill",
                    iconColor: .yellow,
                    title: "Total Moments",
                    value: "\(behaviorsStore.behaviorEvents.count)"
                )

                Divider().padding(.leading, 60)

                EnhancedSettingsInfoRow(
                    icon: "list.bullet",
                    iconColor: .orange,
                    title: "Behavior Types",
                    value: "\(behaviorsStore.behaviorTypes.count)"
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeProvider.resolved.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(themeProvider.resolved.cardBorderColor, lineWidth: themeProvider.resolved.cardBorderWidth)
            )
            .shadow(color: themeProvider.resolved.shadowColor.opacity(themeProvider.resolved.isDark ? 0.3 : 0.04), radius: 8, y: 2)
        }
    }

    // MARK: - Help & Support Section

    private var helpSupportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Help & Support")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                EnhancedSettingsButton(
                    icon: "book.fill",
                    iconGradient: [.blue, .cyan],
                    title: "Help Center",
                    subtitle: "Guides, tips & FAQ"
                ) {
                    showingHelpCenter = true
                }

                Divider().padding(.leading, 60)

                EnhancedSettingsButton(
                    icon: "envelope.fill",
                    iconGradient: [.green, .mint],
                    title: "Contact Us",
                    subtitle: "Feedback, questions & bug reports"
                ) {
                    showingFeedback = true
                }

                Divider().padding(.leading, 60)

                EnhancedSettingsButton(
                    icon: "star.fill",
                    iconGradient: [.yellow, .orange],
                    title: "Rate Tiny Wins",
                    subtitle: "Help us reach more families"
                ) {
                    requestReview()
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeProvider.resolved.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(themeProvider.resolved.cardBorderColor, lineWidth: themeProvider.resolved.cardBorderWidth)
            )
            .shadow(color: themeProvider.resolved.shadowColor.opacity(themeProvider.resolved.isDark ? 0.3 : 0.04), radius: 8, y: 2)
        }
    }

    // MARK: - Connect Section

    private var connectSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connect")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                EnhancedSettingsButton(
                    icon: "square.and.arrow.up.fill",
                    iconGradient: [.pink, .purple],
                    title: "Recommend to a Friend",
                    subtitle: "Share Tiny Wins with other parents"
                ) {
                    showingShareSheet = true
                }

                Divider().padding(.leading, 60)

                EnhancedSettingsButton(
                    icon: "info.circle.fill",
                    iconGradient: [.purple, .blue],
                    title: "About Tiny Wins",
                    subtitle: "Version \(AppInfo.version)"
                ) {
                    showingAbout = true
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeProvider.resolved.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(themeProvider.resolved.cardBorderColor, lineWidth: themeProvider.resolved.cardBorderWidth)
            )
            .shadow(color: themeProvider.resolved.shadowColor.opacity(themeProvider.resolved.isDark ? 0.3 : 0.04), radius: 8, y: 2)
        }
    }

    // MARK: - Privacy & Legal Section

    private var privacyLegalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy & Legal")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                // Analytics Toggle
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [Color.teal.opacity(0.2), Color.cyan.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 42, height: 42)

                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(
                                LinearGradient(colors: [.teal, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Help Improve the App")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)

                        Text("Send anonymous usage data")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: $userPreferences.analyticsEnabled)
                        .labelsHidden()
                        .tint(.teal)
                }
                .padding(14)

                Divider().padding(.leading, 60)

                // Privacy Policy
                EnhancedSettingsLinkButton(
                    icon: "hand.raised.fill",
                    iconGradient: [.blue, .indigo],
                    title: "Privacy Policy",
                    url: AppLinks.privacyPolicyURL
                )

                Divider().padding(.leading, 60)

                // Terms of Service
                EnhancedSettingsLinkButton(
                    icon: "doc.text.fill",
                    iconGradient: [.gray, .secondary],
                    title: "Terms of Service",
                    url: AppLinks.termsOfServiceURL
                )

                Divider().padding(.leading, 60)

                // Changelog
                EnhancedSettingsButton(
                    icon: "clock.arrow.circlepath",
                    iconGradient: [.orange, .red],
                    title: "What's New",
                    subtitle: "Version history"
                ) {
                    showingChangelog = true
                }

                Divider().padding(.leading, 60)

                // Export My Data
                EnhancedSettingsButton(
                    icon: "square.and.arrow.up.fill",
                    iconGradient: [.green, .mint],
                    title: "Export My Data",
                    subtitle: isExporting ? "Preparing..." : "Download all your data"
                ) {
                    exportData()
                }
                .disabled(isExporting)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeProvider.resolved.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(themeProvider.resolved.cardBorderColor, lineWidth: themeProvider.resolved.cardBorderWidth)
            )
            .shadow(color: themeProvider.resolved.shadowColor.opacity(themeProvider.resolved.isDark ? 0.3 : 0.04), radius: 8, y: 2)
        }
        .sheet(isPresented: $showingExportSheet) {
            if let url = exportFileURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Export Error", isPresented: .init(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(exportError ?? "An error occurred while exporting your data.")
        }
    }

    // MARK: - Data Export

    private func exportData() {
        isExporting = true
        exportError = nil

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let url = try repository.exportDataAsJSON()
                DispatchQueue.main.async {
                    exportFileURL = url
                    showingExportSheet = true
                    isExporting = false
                }
            } catch {
                DispatchQueue.main.async {
                    exportError = error.localizedDescription
                    isExporting = false
                }
            }
        }
    }

    // MARK: - Developer Section

    private var developerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 12))
                Text("Developer")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.orange)
            .padding(.leading, 4)

            VStack(spacing: 12) {
                // Unlock Plus Toggle
                #if DEBUG
                if DeveloperConfig.showUnlockPlusToggle {
                    Toggle(isOn: $featureFlags.debugUnlockPlus) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 42, height: 42)

                                Image(systemName: "crown.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.orange)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Unlock Plus")
                                    .font(.system(size: 16, weight: .medium))

                                Text("For testing only")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .tint(.purple)

                    if featureFlags.debugUnlockPlus {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text("Plus features active")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.green)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                #endif

                // Show Onboarding Button
                if DeveloperConfig.showOnboardingTrigger {
                    Divider()
                        .padding(.vertical, 4)

                    Button(action: {
                        triggerOnboardingFlow()
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 42, height: 42)

                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Show Onboarding")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)

                                Text("Test the welcome flow")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Partner Attribution Toggle
                #if DEBUG
                if DeveloperConfig.showPartnerAttributionToggle {
                    Divider()
                        .padding(.vertical, 4)

                    Toggle(isOn: $userPreferences.showPartnerAttribution) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.cyan.opacity(0.15))
                                    .frame(width: 42, height: 42)

                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.cyan)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Partner Attribution")
                                    .font(.system(size: 16, weight: .medium))

                                Text("Show 'Logged by' on events")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .tint(.cyan)
                }

                // Partner Dashboard Link
                if DeveloperConfig.showPartnerDashboardLink {
                    Divider()
                        .padding(.vertical, 4)

                    NavigationLink(destination: PartnerDashboardView()) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.pink.opacity(0.15))
                                    .frame(width: 42, height: 42)

                                Image(systemName: "heart.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.pink)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Partner Dashboard")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)

                                Text("View co-parent activity")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Demo Paywall Toggle
                if DeveloperConfig.showDemoPaywallToggle {
                    Divider()
                        .padding(.vertical, 4)

                    Toggle(isOn: $userPreferences.showDemoPaywall) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 42, height: 42)

                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.green)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Demo Paywall")
                                    .font(.system(size: 16, weight: .medium))

                                Text("Show mock pricing without StoreKit")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .tint(.green)
                }

                // Firebase Sync Toggle
                if DeveloperConfig.showFirebaseSyncToggle {
                    Divider()
                        .padding(.vertical, 4)

                    Toggle(isOn: $userPreferences.firebaseSyncEnabled) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 42, height: 42)

                                Image(systemName: "cloud.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.orange)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Firebase Sync")
                                    .font(.system(size: 16, weight: .medium))

                                Text("Cloud sync, Sign-In, co-parent")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .tint(.orange)

                    if userPreferences.firebaseSyncEnabled {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.icloud.fill")
                                .foregroundColor(.orange)
                            Text("Firebase enabled - restart app for changes")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.orange)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(10)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "iphone")
                                .foregroundColor(.secondary)
                            Text("Local-only mode - restart app for changes")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                #endif

                // Load Demo Data Button
                if DeveloperConfig.showLoadDemoData {
                    Divider()
                        .padding(.vertical, 4)

                    Button(action: {
                        showingDemoDataAlert = true
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 42, height: 42)

                                Image(systemName: "sparkles.rectangle.stack.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.green)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Load Demo Data")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)

                                Text("4 kids, 45 days of data, all features")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if isLoadingDemoData {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoadingDemoData)
                }

                // Dev Erase Data Button (more aggressive than Danger Zone)
                if DeveloperConfig.showDevEraseData {
                    Divider()
                        .padding(.vertical, 4)

                    Button(action: {
                        showingEraseDataAlert = true
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.red.opacity(0.15))
                                    .frame(width: 42, height: 42)

                                Image(systemName: "trash.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.red)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Reset App (Dev)")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.red)

                                Text("Erase local + cloud data → onboarding")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if isErasingData {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.red.opacity(0.5))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isErasingData)
                }

                // Backend Info
                VStack(alignment: .leading, spacing: 6) {
                    Divider()
                        .padding(.vertical, 4)

                    HStack {
                        Text("Backend:")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(repository.backendName)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.orange)
                    }

                    HStack {
                        Text("Firebase:")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(AppConfiguration.isFirebaseEnabled ? "Enabled" : "Disabled")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(AppConfiguration.isFirebaseEnabled ? .green : .secondary)
                    }

                    if AppConfiguration.isSignedIn {
                        HStack {
                            Text("Signed In:")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Yes")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeProvider.resolved.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Danger Zone Section

    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Danger Zone")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.red.opacity(0.8))
                .padding(.leading, 4)

            Button(action: { showingEraseDataAlert = true }) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 42, height: 42)

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.red)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Erase all app data")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)

                        Text("This cannot be undone")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red.opacity(0.5))
                }
                .padding(14)
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeProvider.resolved.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.red.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - Helper Methods

    /// Open App Store subscription management page
    /// Required by Apple for apps with auto-renewable subscriptions
    private func openSubscriptionManagement() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }

    /// Save the edited family name
    private func saveFamilyName() {
        let trimmedName = editedFamilyName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        var family = repository.getFamily()
        family.name = trimmedName
        repository.updateFamily(family)
    }

    /// Load demo data for testing all app features
    private func loadDemoData() {
        isLoadingDemoData = true

        Task {
            // Load demo data through repository
            await MainActor.run {
                repository.loadDemoData()
            }

            // Clear insights cooldowns so demo cards show immediately
            await MainActor.run {
                CooldownManager().clearAllCooldowns()
            }

            // Reload all stores to reflect new data
            await MainActor.run {
                childrenStore.loadChildren()
                behaviorsStore.loadData()
            }

            // Reset insights child selection to first demo child
            // This ensures the selected child is valid for the demo data
            await MainActor.run {
                if let firstChild = childrenStore.activeChildren.first {
                    // Post notification so InsightsHomeView can reset its engine and selection
                    NotificationCenter.default.post(
                        name: .demoDataDidLoad,
                        object: nil,
                        userInfo: ["firstChildId": firstChild.id]
                    )
                }
            }

            // Small delay for UI update
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            await MainActor.run {
                isLoadingDemoData = false
                // Dismiss settings to show the new data
                dismiss()
            }
        }
    }

    /// Trigger onboarding flow without erasing data (for testing)
    private func triggerOnboardingFlow() {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            userPreferences.resetOnboarding()
        }
    }

    /// Perform full data erase (local + cloud) and trigger onboarding
    private func performFullDataErase() {
        isErasingData = true
        showingEraseConfirmation = false

        Task {
            // Clear all local data via repository
            repository.clearAllData()

            // Clear stored family ID so a fresh one is created on next sign-in
            AppConfiguration.storedFamilyId = nil

            // Reset user preferences (coach marks, banner dates, etc.)
            await MainActor.run {
                userPreferences.resetOnboarding()
                userPreferences.resetAllCoachMarks()
                userPreferences.resetAllBannerDates()
            }

            // Reload stores to reflect empty state
            await MainActor.run {
                childrenStore.loadChildren()
                behaviorsStore.loadData()
            }

            // Small delay to ensure UI updates
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

            await MainActor.run {
                isErasingData = false
                // Dismiss settings and let ContentView show onboarding
                dismiss()
            }
        }
    }

    /// Legacy erase function (kept for backwards compatibility)
    private func eraseAllData() {
        performFullDataErase()
    }
}

// MARK: - Settings Quick Action Button

private struct SettingsQuickActionButton: View {
    let icon: String
    let title: String
    let gradient: [Color]
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient.map { $0.opacity(0.15) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(
                            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .frame(width: 80)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(gradient[0].opacity(0.2), lineWidth: 1)
            )
            .shadow(color: gradient[0].opacity(0.1), radius: 4, y: 2)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.25)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Enhanced Settings Button

private struct EnhancedSettingsButton: View {
    let icon: String
    let iconGradient: [Color]
    let title: String
    let subtitle: String
    var showPlusBadge: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: iconGradient.map { $0.opacity(0.2) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(
                            LinearGradient(colors: iconGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)

                        if showPlusBadge {
                            PlusBadge(small: true)
                        }
                    }

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(minHeight: 44) // Accessibility: minimum tap target
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Enhanced Settings Info Row

private struct EnhancedSettingsInfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }

            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)

            Spacer()

            Text(value)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
        }
        .padding(14)
    }
}

// MARK: - Erase Data Confirmation View

struct EraseDataConfirmationView: View {
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @State private var confirmationText = ""
    
    private var isConfirmEnabled: Bool {
        confirmationText.uppercased() == "RESET"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Warning icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.red)
                }
                
                // Title
                Text("Are you sure?")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Message
                Text("To confirm, type RESET in capital letters.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Text field
                TextField("Type RESET to confirm", text: $confirmationText)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.allCharacters)
                    .padding(.horizontal, 32)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: onConfirm) {
                        Text("Confirm")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isConfirmEnabled ? Color.red : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(AppStyles.buttonCornerRadius)
                    }
                    .disabled(!isConfirmEnabled)
                    
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .padding(.top, 32)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Allowance Settings View

struct AllowanceSettingsView: View {
    @EnvironmentObject private var repository: Repository
    @EnvironmentObject private var behaviorsStore: BehaviorsStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEnabled: Bool
    @State private var selectedCurrency: String
    @State private var pointsPerUnit: String
    
    init() {
        _isEnabled = State(initialValue: false)
        _selectedCurrency = State(initialValue: "USD")
        _pointsPerUnit = State(initialValue: "10")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Enable Allowance", isOn: $isEnabled)
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("When enabled, certain behaviors can earn money in addition to points.")
                        
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text("Recommended: Start with stars only for a few weeks. You can turn on allowance later if it fits your family.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }
                
                if isEnabled {
                    Section("Currency") {
                        Picker("Currency", selection: $selectedCurrency) {
                            ForEach(AllowanceSettings.commonCurrencies, id: \.code) { currency in
                                Text("\(currency.code) - \(currency.name)")
                                    .tag(currency.code)
                            }
                        }
                    }
                    
                    Section {
                        HStack {
                            Text("Points per 1 \(currencySymbol)")
                            Spacer()
                            TextField("10", text: $pointsPerUnit)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                        }
                    } footer: {
                        Text("Example: If set to 10, earning 10 points = \(currencySymbol)1.00")
                    }
                    
                    Section("Monetizable Behaviors") {
                        let monetized = behaviorsStore.behaviorTypes.filter { $0.isMonetized && $0.isActive }

                        if monetized.isEmpty {
                            Text("No behaviors are set to earn allowance.")
                                .foregroundColor(.secondary)

                            Text("Go to Manage Behaviors to enable allowance for specific tasks.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(monetized) { behavior in
                                HStack {
                                    Image(systemName: behavior.iconName)
                                        .foregroundColor(.green)
                                    Text(behavior.name)
                                    Spacer()
                                    Text("+\(behavior.defaultPoints) pts")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    Section("Important Notes") {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Good for chores and extra responsibilities", systemImage: "checkmark.circle")
                            Label("Skip everyday courtesy behaviors", systemImage: "heart.fill")
                            Label("Stars alone work great for most families", systemImage: "star.fill")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Allowance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear {
                let settings = repository.getAllowanceSettings()
                isEnabled = settings.isEnabled
                selectedCurrency = settings.currencyCode
                pointsPerUnit = String(Int(settings.pointsPerUnitCurrency))
            }
        }
    }
    
    private var currencySymbol: String {
        let locale = Locale(identifier: Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: selectedCurrency]))
        return locale.currencySymbol ?? "$"
    }
    
    private func save() {
        let points = Double(pointsPerUnit) ?? 10
        repository.updateAllowanceSettings(AllowanceSettings(
            isEnabled: isEnabled,
            currencyCode: selectedCurrency,
            pointsPerUnitCurrency: max(1, points)
        ))
        dismiss()
    }
}

// MARK: - Enhanced About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeProvider: ThemeProvider
    @State private var animateIcon = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Hero Section with animated app icon
                    VStack(spacing: 20) {
                        ZStack {
                            // Outer glow rings
                            ForEach(0..<3, id: \.self) { i in
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [.purple.opacity(0.2), .blue.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                                    .frame(width: CGFloat(120 + i * 30), height: CGFloat(120 + i * 30))
                                    .scaleEffect(animateIcon ? 1 : 0.9)
                                    .opacity(animateIcon ? 0.6 - Double(i) * 0.15 : 0.3)
                            }

                            // App Icon - consistent across the app
                            AppIconView(size: 100, cornerRadius: 28)
                                .scaleEffect(animateIcon ? 1.05 : 1)
                        }
                        .onAppear {
                            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                                animateIcon = true
                            }
                        }

                        VStack(spacing: 8) {
                            Text("Tiny Wins")
                                .font(.system(size: 28, weight: .bold))

                            Text("Version 1.0.0")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(themeProvider.streakInactiveColor)
                                .cornerRadius(8)

                            Text("Turn small moments into big progress")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.top, 20)

                    // Features Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What makes Tiny Wins special")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)

                        VStack(spacing: 0) {
                            EnhancedAboutSection(
                                icon: "heart.fill",
                                gradient: [.pink, .red],
                                title: "Positive Reinforcement",
                                description: "Focus on celebrating good behaviors rather than punishing bad ones."
                            )

                            Divider().padding(.leading, 60)

                            EnhancedAboutSection(
                                icon: "hand.raised.fill",
                                gradient: [.blue, .cyan],
                                title: "Low Friction",
                                description: "Log behaviors in just two taps. No complicated setup required."
                            )

                            Divider().padding(.leading, 60)

                            EnhancedAboutSection(
                                icon: "person.2.fill",
                                gradient: [.green, .mint],
                                title: "Family Agreement",
                                description: "Create transparency with kid-friendly views of rules and rewards."
                            )

                            Divider().padding(.leading, 60)

                            EnhancedAboutSection(
                                icon: "sparkles",
                                gradient: [.orange, .yellow],
                                title: "Parent Support",
                                description: "Daily check-ins and gentle guidance to support your parenting journey."
                            )
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(themeProvider.resolved.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(themeProvider.resolved.cardBorderColor, lineWidth: themeProvider.resolved.cardBorderWidth)
                        )
                        .shadow(color: themeProvider.resolved.shadowColor.opacity(themeProvider.resolved.isDark ? 0.3 : 0.04), radius: 8, y: 2)
                    }
                    .padding(.horizontal, 16)

                    // Footer
                    VStack(spacing: 16) {
                        HStack(spacing: 8) {
                            Text("Made with")
                            Image(systemName: "heart.fill")
                                .foregroundColor(.pink)
                            Text("for families everywhere")
                        }
                        .font(.system(size: 14))
                        .foregroundColor(themeProvider.resolved.secondaryTextColor)

                        Text("© 2024 Tiny Wins")
                            .font(.system(size: 12))
                            .foregroundColor(themeProvider.resolved.secondaryTextColor.opacity(0.7))
                    }
                    .padding(.vertical, 20)
                }
                .padding(.bottom, 20)
            }
            .background(themeProvider.resolved.backgroundColor)
            .navigationTitle("About Tiny Wins")
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar(themeProvider)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct EnhancedAboutSection: View {
    let icon: String
    let gradient: [Color]
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: gradient.map { $0.opacity(0.2) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(
                        LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(14)
    }
}

// Legacy AboutSection for compatibility
struct AboutSection: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Enhanced How It Works View

struct HowItWorksView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeProvider: ThemeProvider

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Hero Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [.yellow.opacity(0.4), .orange.opacity(0.1), .clear],
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 80
                                    )
                                )
                                .frame(width: 140, height: 140)

                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.yellow, .orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 90, height: 90)
                                    .shadow(color: .orange.opacity(0.4), radius: 15, y: 8)

                                Image(systemName: "star.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            }
                        }

                        VStack(spacing: 8) {
                            Text("How Tiny Wins Works")
                                .font(.system(size: 24, weight: .bold))

                            Text("Three simple steps to transform your family's days")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 16)

                    // Steps
                    VStack(spacing: 0) {
                        EnhancedHowItWorksStep(
                            number: 1,
                            icon: "plus.circle.fill",
                            gradient: [.green, .mint],
                            title: "Notice the good stuff",
                            description: "When your child does something you want to celebrate, tap to add a moment. It takes just two taps.",
                            isLast: false
                        )

                        EnhancedHowItWorksStep(
                            number: 2,
                            icon: "gift.fill",
                            gradient: [.purple, .pink],
                            title: "Set exciting goals",
                            description: "Create small reward goals together: family activities, extra playtime, or special treats they will love working toward.",
                            isLast: false
                        )

                        EnhancedHowItWorksStep(
                            number: 3,
                            icon: "chart.line.uptrend.xyaxis",
                            gradient: [.blue, .cyan],
                            title: "Watch progress unfold",
                            description: "Use simple insights to see patterns emerge, celebrate milestones, and adjust goals together as a family.",
                            isLast: true
                        )
                    }
                    .padding(.horizontal, 16)

                    // Pro Tip Card
                    VStack(spacing: 12) {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.yellow.opacity(0.2))
                                    .frame(width: 44, height: 44)

                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.yellow)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pro Tip")
                                    .font(.system(size: 15, weight: .bold))

                                Text("Consistency beats perfection")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }

                        Text("Even noticing one small win each day makes a difference over time. You do not need to track everything, just what matters most.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.yellow.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.yellow.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .background(themeProvider.resolved.backgroundColor)
            .navigationTitle("How It Works")
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar(themeProvider)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Enhanced How It Works Step

private struct EnhancedHowItWorksStep: View {
    let number: Int
    let icon: String
    let gradient: [Color]
    let title: String
    let description: String
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline connector
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: gradient[0].opacity(0.3), radius: 8, y: 4)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [gradient[0].opacity(0.5), gradient[0].opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 3, height: 40)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text("Step \(number)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
                    )
                    .textCase(.uppercase)

                Text(title)
                    .font(.system(size: 17, weight: .semibold))

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, isLast ? 0 : 24)

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// Legacy HowItWorksStep kept for compatibility
struct HowItWorksStep: View {
    @EnvironmentObject private var themeProvider: ThemeProvider
    let number: Int
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
        .background(themeProvider.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Enhanced Settings Link Button (for URLs)

private struct EnhancedSettingsLinkButton: View {
    let icon: String
    let iconGradient: [Color]
    let title: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: iconGradient.map { $0.opacity(0.2) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(
                            LinearGradient(colors: iconGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(minHeight: 44) // Accessibility: minimum tap target
            .padding(14)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("\(title). Opens in Safari.")
        .accessibilityAddTraits(.isLink)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - App Links & Info

enum AppLinks {
    // TODO: Replace these with your actual URLs before App Store submission
    static let privacyPolicyURL = "https://tinywins.app/privacy"
    static let termsOfServiceURL = "https://tinywins.app/terms"
    static let appStoreURL = "https://apps.apple.com/app/tiny-wins/id123456789" // Replace with actual ID
    static let instagramURL = "https://instagram.com/tinywinsapp"
}

enum AppInfo {
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    static var fullVersion: String {
        "\(version) (\(build))"
    }
}

// MARK: - FAQ View

struct FAQView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeProvider: ThemeProvider

    private let faqs: [(question: String, answer: String)] = [
        (
            "What is Tiny Wins?",
            "Tiny Wins helps parents notice and celebrate their children's positive behaviors. By logging small wins throughout the day, you build a positive feedback loop that encourages good habits."
        ),
        (
            "How do I add a behavior?",
            "Tap the '+' button on the Today tab, select your child, then choose the behavior you want to log. It takes just two taps!"
        ),
        (
            "What are stars for?",
            "Stars are points your child earns for positive behaviors. They can work toward goals you set together, like a special activity or treat."
        ),
        (
            "How do goals work?",
            "Goals are rewards your child can work toward by earning stars. Set a target number of stars and watch their progress. When they reach the goal, celebrate together!"
        ),
        (
            "Can both parents use the app?",
            "Yes! With TinyWins Plus, you can invite a co-parent to sync your family data. Both parents can log behaviors and see progress."
        ),
        (
            "Is my data safe?",
            "Absolutely. Your family data is encrypted and stored securely. We never share your data with third parties. See our Privacy Policy for details."
        ),
        (
            "What if my child has a bad day?",
            "That is completely okay. Tiny Wins focuses on celebrating the good, not punishing the bad. Even small wins count. Tomorrow is a fresh start."
        ),
        (
            "Can I customize behaviors?",
            "Yes! Go to Settings > Manage Behaviors to add, edit, or remove behaviors that fit your family's needs."
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        // Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.indigo.opacity(0.15))
                                    .frame(width: 70, height: 70)

                                Image(systemName: "text.book.closed.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.indigo)
                            }

                            Text("Frequently Asked Questions")
                                .font(.system(size: 20, weight: .bold))
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 8)

                        // FAQ Items
                        ForEach(Array(faqs.enumerated()), id: \.offset) { index, faq in
                            FAQItem(question: faq.question, answer: faq.answer, themeProvider: themeProvider) {
                                // Scroll to expanded item after animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        proxy.scrollTo("faq-\(index)", anchor: .top)
                                    }
                                }
                            }
                            .id("faq-\(index)")
                        }

                        // Contact Section
                        VStack(spacing: 12) {
                            Text("Still have questions?")
                                .font(.subheadline)
                                .foregroundColor(themeProvider.resolved.secondaryTextColor)

                            Text("Send us a message via Settings > Send Feedback")
                                .font(.caption)
                                .foregroundColor(themeProvider.resolved.secondaryTextColor)
                        }
                        .padding(.vertical, 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .background(themeProvider.resolved.backgroundColor)
            .navigationTitle("FAQ")
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar(themeProvider)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct FAQItem: View {
    let question: String
    let answer: String
    let themeProvider: ThemeProvider
    var onExpand: (() -> Void)? = nil
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                // Notify parent when expanded (for scroll anchoring)
                if isExpanded {
                    onExpand?()
                }
            } label: {
                HStack {
                    Text(question)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeProvider.resolved.primaryTextColor)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 12)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeProvider.resolved.secondaryTextColor)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .frame(minHeight: 44) // Accessibility: minimum tap target
                .padding(16)
                .contentShape(Rectangle())
            }
            .accessibilityLabel(question)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
            .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand")")
            .accessibilityAddTraits(.isButton)

            if isExpanded {
                Text(answer)
                    .font(.system(size: 15))
                    .foregroundColor(themeProvider.resolved.secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.resolved.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(themeProvider.resolved.cardBorderColor, lineWidth: themeProvider.resolved.cardBorderWidth)
        )
        .shadow(color: themeProvider.resolved.shadowColor.opacity(themeProvider.resolved.isDark ? 0.3 : 0.04), radius: 8, y: 2)
    }
}

// MARK: - Changelog View

struct ChangelogView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeProvider: ThemeProvider

    private let releases: [(version: String, date: String, changes: [String])] = [
        (
            "1.0.0",
            "December 2024",
            [
                "Initial release",
                "Track positive behaviors for your children",
                "Set goals and rewards",
                "Kid-friendly view for showing progress",
                "Daily insights and streaks",
                "TinyWins Plus subscription for families"
            ]
        )
        // Add more releases here as you update the app
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 70, height: 70)

                            Image(systemName: "sparkles")
                                .font(.system(size: 30))
                                .foregroundColor(.orange)
                        }

                        Text("What's New")
                            .font(.system(size: 20, weight: .bold))

                        Text("See what we've been working on")
                            .font(.subheadline)
                            .foregroundColor(themeProvider.resolved.secondaryTextColor)
                    }
                    .padding(.top, 20)

                    // Releases
                    ForEach(Array(releases.enumerated()), id: \.offset) { index, release in
                        ChangelogReleaseCard(
                            version: release.version,
                            date: release.date,
                            changes: release.changes,
                            isLatest: index == 0,
                            themeProvider: themeProvider
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(themeProvider.resolved.backgroundColor)
            .navigationTitle("Changelog")
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar(themeProvider)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct ChangelogReleaseCard: View {
    let version: String
    let date: String
    let changes: [String]
    let isLatest: Bool
    let themeProvider: ThemeProvider

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Version Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Version \(version)")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(themeProvider.resolved.primaryTextColor)

                        if isLatest {
                            Text("LATEST")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(6)
                        }
                    }

                    Text(date)
                        .font(.system(size: 13))
                        .foregroundColor(themeProvider.resolved.secondaryTextColor)
                }

                Spacer()
            }

            // Changes
            VStack(alignment: .leading, spacing: 10) {
                ForEach(changes, id: \.self) { change in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                            .padding(.top, 2)

                        Text(change)
                            .font(.system(size: 15))
                            .foregroundColor(themeProvider.resolved.primaryTextColor)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeProvider.resolved.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(themeProvider.resolved.cardBorderColor, lineWidth: themeProvider.resolved.cardBorderWidth)
        )
        .shadow(color: themeProvider.resolved.shadowColor.opacity(themeProvider.resolved.isDark ? 0.3 : 0.04), radius: 8, y: 2)
    }
}

// MARK: - Help Center View

struct HelpCenterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeProvider: ThemeProvider
    @State private var selectedTab: HelpTab = .guide

    enum HelpTab: String, CaseIterable {
        case guide = "Guide"
        case faq = "FAQ"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Help Section", selection: $selectedTab) {
                    ForEach(HelpTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Content
                TabView(selection: $selectedTab) {
                    guideContent
                        .tag(HelpTab.guide)

                    faqContent
                        .tag(HelpTab.faq)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(themeProvider.resolved.backgroundColor)
            .navigationTitle("Help Center")
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar(themeProvider)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Guide Content

    private var guideContent: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Hero Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.yellow.opacity(0.4), .orange.opacity(0.1), .clear],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 140, height: 140)

                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 90, height: 90)
                                .shadow(color: .orange.opacity(0.4), radius: 15, y: 8)

                            Image(systemName: "star.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                    }

                    VStack(spacing: 8) {
                        Text("How Tiny Wins Works")
                            .font(.system(size: 24, weight: .bold))

                        Text("Three simple steps to transform your family's days")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 16)

                // Steps
                VStack(spacing: 0) {
                    EnhancedHowItWorksStep(
                        number: 1,
                        icon: "plus.circle.fill",
                        gradient: [.green, .mint],
                        title: "Notice the good stuff",
                        description: "When your child does something you want to celebrate, tap to add a moment. It takes just two taps.",
                        isLast: false
                    )

                    EnhancedHowItWorksStep(
                        number: 2,
                        icon: "gift.fill",
                        gradient: [.purple, .pink],
                        title: "Set exciting goals",
                        description: "Create small reward goals together: family activities, extra playtime, or special treats they will love working toward.",
                        isLast: false
                    )

                    EnhancedHowItWorksStep(
                        number: 3,
                        icon: "chart.line.uptrend.xyaxis",
                        gradient: [.blue, .cyan],
                        title: "Watch progress unfold",
                        description: "Use simple insights to see patterns emerge, celebrate milestones, and adjust goals together as a family.",
                        isLast: true
                    )
                }
                .padding(.horizontal, 16)

                // Pro Tip Card
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.yellow.opacity(0.2))
                                .frame(width: 44, height: 44)

                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.yellow)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pro Tip")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Log moments right when they happen")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }

                    Text("The best time to capture a win is right away. Keep Tiny Wins handy on your home screen for quick access.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeProvider.resolved.cardBackground)
                )
                .shadow(color: themeProvider.resolved.shadowColor.opacity(0.04), radius: 8, y: 2)
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 32)
        }
    }

    // MARK: - FAQ Content

    private let faqs: [(question: String, answer: String)] = [
        (
            "What is Tiny Wins?",
            "Tiny Wins helps parents notice and celebrate their children's positive behaviors. By logging small wins throughout the day, you build a positive feedback loop that encourages good habits."
        ),
        (
            "How do I add a behavior?",
            "Tap the '+' button on the Today tab, select your child, then choose the behavior you want to log. It takes just two taps!"
        ),
        (
            "What are stars for?",
            "Stars are points your child earns for positive behaviors. They can work toward goals you set together, like a special activity or treat."
        ),
        (
            "How do goals work?",
            "Goals are rewards your child can work toward by earning stars. Set a target number of stars and watch their progress. When they reach the goal, celebrate together!"
        ),
        (
            "Can both parents use the app?",
            "Yes! With TinyWins Plus, you can invite a co-parent to sync your family data. Both parents can log behaviors and see progress."
        ),
        (
            "Is my data safe?",
            "Absolutely. Your family data is encrypted and stored securely. We never share your data with third parties. See our Privacy Policy for details."
        ),
        (
            "What if my child has a bad day?",
            "That is completely okay. Tiny Wins focuses on celebrating the good, not punishing the bad. Even small wins count. Tomorrow is a fresh start."
        ),
        (
            "Can I customize behaviors?",
            "Yes! Go to Settings > Manage Behaviors to add, edit, or remove behaviors that fit your family's needs."
        )
    ]

    private var faqContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.indigo.opacity(0.15))
                                .frame(width: 70, height: 70)

                            Image(systemName: "text.book.closed.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.indigo)
                        }

                        Text("Frequently Asked Questions")
                            .font(.system(size: 20, weight: .bold))
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                    // FAQ Items
                    ForEach(Array(faqs.enumerated()), id: \.offset) { index, faq in
                        FAQItem(question: faq.question, answer: faq.answer, themeProvider: themeProvider) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo("help-faq-\(index)", anchor: .top)
                                }
                            }
                        }
                        .id("help-faq-\(index)")
                    }

                    // Contact Section
                    VStack(spacing: 12) {
                        Text("Still have questions?")
                            .font(.subheadline)
                            .foregroundColor(themeProvider.resolved.secondaryTextColor)

                        Text("Tap 'Contact Us' in Help & Support")
                            .font(.caption)
                            .foregroundColor(themeProvider.resolved.secondaryTextColor)
                    }
                    .padding(.vertical, 20)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let repository = Repository.preview
    let childrenStore = ChildrenStore(repository: repository)
    let behaviorsStore = BehaviorsStore(repository: repository)
    let userPreferences = UserPreferencesStore()
    let coordinator = AppCoordinator()

    SettingsView()
        .environmentObject(repository)
        .environmentObject(childrenStore)
        .environmentObject(behaviorsStore)
        .environmentObject(userPreferences)
        .environmentObject(coordinator)
}
