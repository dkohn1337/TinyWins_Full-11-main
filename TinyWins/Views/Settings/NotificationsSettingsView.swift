import SwiftUI
import UserNotifications

/// Notification settings for daily and gentle reminders
struct NotificationsSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var notificationService: NotificationService
    
    @State private var dailyReminderEnabled: Bool = false
    @State private var reminderTime: Date = Date()
    @State private var gentleReminderEnabled: Bool = false
    @State private var showingPermissionAlert = false
    @State private var permissionExplicitlyDenied = false  // M2 FIX: Track if user denied

    var body: some View {
        NavigationStack {
            List {
                // M2 FIX: Authorization Status with better UX for denied state
                if !notificationService.isAuthorized {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: permissionExplicitlyDenied ? "bell.badge.slash.fill" : "bell.slash.fill")
                                    .foregroundColor(permissionExplicitlyDenied ? .red : .orange)
                                    .font(.title2)

                                Text(permissionExplicitlyDenied ? "Notifications Blocked" : "Notifications are off")
                                    .font(.headline)
                            }

                            Text(permissionExplicitlyDenied
                                ? "You previously declined notifications. To enable reminders, open Settings and allow notifications for TinyWins."
                                : "Enable notifications to get gentle reminders to log your child's wins.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            if permissionExplicitlyDenied {
                                // M2 FIX: Direct link to Settings when previously denied
                                Button(action: openAppSettings) {
                                    HStack {
                                        Image(systemName: "gear")
                                        Text("Open Settings")
                                    }
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color(.systemGray5))
                                    .foregroundColor(.primary)
                                    .cornerRadius(8)
                                }
                            } else {
                                Button(action: requestPermission) {
                                    Text("Enable Notifications")
                                        .font(.subheadline.weight(.medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.accentColor)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Daily Reminder
                Section {
                    Toggle(isOn: $dailyReminderEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Daily Reminder")
                                    .font(.body)
                                
                                Text("A gentle nudge to log moments")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(!notificationService.isAuthorized)
                    .onChange(of: dailyReminderEnabled) { _, newValue in
                        if newValue && !notificationService.isAuthorized {
                            dailyReminderEnabled = false
                            showingPermissionAlert = true
                        } else {
                            notificationService.dailyReminderEnabled = newValue
                        }
                    }
                    
                    if dailyReminderEnabled && notificationService.isAuthorized {
                        DatePicker(
                            "Reminder Time",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: reminderTime) { _, newValue in
                            notificationService.dailyReminderTime = newValue
                        }
                    }
                } header: {
                    Text("Daily Reminder")
                } footer: {
                    if notificationService.isAuthorized {
                        Text("We'll send a friendly reminder at this time each day.")
                    }
                }
                
                // Gentle Inactivity Reminder (replaces Streak Reminder)
                Section {
                    Toggle(isOn: $gentleReminderEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Check-in Reminder")
                                    .font(.body)
                                
                                Text("A friendly nudge if you haven't logged in a while")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(!notificationService.isAuthorized)
                    .onChange(of: gentleReminderEnabled) { _, newValue in
                        if newValue && !notificationService.isAuthorized {
                            gentleReminderEnabled = false
                            showingPermissionAlert = true
                        } else {
                            notificationService.gentleReminderEnabled = newValue
                        }
                    }
                } header: {
                    Text("Occasional Check-in")
                } footer: {
                    Text("If you've been away for a few days, we'll send one gentle reminder. No pressure, just a friendly check-in.")
                }
                
                // Tips Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text("Notification Tips")
                                .font(.subheadline.weight(.medium))
                        }
                        
                        Text("Most parents find evening reminders (around 7-8 PM) work best for reflecting on the day's wins.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCurrentSettings()
            }
            .alert("Notifications Disabled", isPresented: $showingPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("To enable reminders, please allow notifications in your device settings.")
            }
        }
    }
    
    private func loadCurrentSettings() {
        dailyReminderEnabled = notificationService.dailyReminderEnabled
        reminderTime = notificationService.dailyReminderTime
        gentleReminderEnabled = notificationService.gentleReminderEnabled
        notificationService.checkAuthorizationStatus()

        // M2 FIX: Check if notifications were explicitly denied
        checkForDeniedPermissions()
    }

    /// M2 FIX: Check notification authorization status to detect if previously denied
    private func checkForDeniedPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                // If status is .denied, user explicitly declined
                permissionExplicitlyDenied = settings.authorizationStatus == .denied
            }
        }
    }

    private func requestPermission() {
        notificationService.requestAuthorization { granted in
            if granted {
                loadCurrentSettings()
            } else {
                // M2 FIX: Check if this was a denial
                checkForDeniedPermissions()
                if permissionExplicitlyDenied {
                    // Don't show alert, the UI will update to show "Open Settings"
                } else {
                    showingPermissionAlert = true
                }
            }
        }
    }

    /// M2 FIX: Open app settings directly
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview {
    NotificationsSettingsView()
}
