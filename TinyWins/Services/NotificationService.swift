import Foundation
import UserNotifications

/// Manages local notifications for TinyWins
final class NotificationService: ObservableObject {
    /// Shared singleton instance for backward compatibility.
    /// New code should use dependency injection via DependencyContainer.
    static let shared = NotificationService()

    // MARK: - Published State
    @Published private(set) var isAuthorized = false
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    // MARK: - UserDefaults Keys
    private let hasRequestedPermissionKey = "hasRequestedNotificationPermission"
    private let dailyReminderEnabledKey = "dailyReminderEnabled"
    private let dailyReminderHourKey = "dailyReminderHour"
    private let dailyReminderMinuteKey = "dailyReminderMinute"
    private let gentleReminderEnabledKey = "gentleReminderEnabled"  // Replaces streakReminderEnabled

    // MARK: - Settings
    var hasRequestedPermission: Bool {
        get { UserDefaults.standard.bool(forKey: hasRequestedPermissionKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasRequestedPermissionKey) }
    }
    
    var dailyReminderEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: dailyReminderEnabledKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: dailyReminderEnabledKey)
            objectWillChange.send()
            if newValue {
                scheduleDailyReminder()
            } else {
                cancelDailyReminder()
            }
        }
    }
    
    var dailyReminderHour: Int {
        get { UserDefaults.standard.object(forKey: dailyReminderHourKey) as? Int ?? 19 }
        set {
            UserDefaults.standard.set(newValue, forKey: dailyReminderHourKey)
            if dailyReminderEnabled { scheduleDailyReminder() }
        }
    }
    
    var dailyReminderMinute: Int {
        get { UserDefaults.standard.object(forKey: dailyReminderMinuteKey) as? Int ?? 0 }
        set {
            UserDefaults.standard.set(newValue, forKey: dailyReminderMinuteKey)
            if dailyReminderEnabled { scheduleDailyReminder() }
        }
    }
    
    var gentleReminderEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: gentleReminderEnabledKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: gentleReminderEnabledKey)
            objectWillChange.send()
        }
    }
    
    var dailyReminderTime: Date {
        get {
            var components = DateComponents()
            components.hour = dailyReminderHour
            components.minute = dailyReminderMinute
            return Calendar.current.date(from: components) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            dailyReminderHour = components.hour ?? 19
            dailyReminderMinute = components.minute ?? 0
        }
    }
    
    // MARK: - Notification Identifiers
    private let dailyReminderIdentifier = "com.tinywins.dailyReminder"
    private let gentleReminderIdentifier = "com.tinywins.gentleReminder"

    /// Creates a new NotificationService instance.
    /// Use `shared` singleton for backward compatibility or inject via DependencyContainer.
    init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// Request notification permission with parenting-friendly messaging
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        hasRequestedPermission = true
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                self?.checkAuthorizationStatus()
                completion(granted)
                
                if granted {
                    // Auto-enable daily reminder on first grant
                    if !UserDefaults.standard.bool(forKey: self?.dailyReminderEnabledKey ?? "") {
                        self?.dailyReminderEnabled = true
                    }
                }
            }
        }
    }
    
    // MARK: - Daily Reminder
    
    func scheduleDailyReminder() {
        guard isAuthorized else { return }
        
        // Cancel existing
        cancelDailyReminder()
        
        // Create content
        let content = UNMutableNotificationContent()
        content.title = "Time to catch a Tiny Win"
        content.body = dailyReminderMessages.randomElement() ?? "Notice something good today?"
        content.sound = .default
        
        // Create trigger - daily at set time
        var dateComponents = DateComponents()
        dateComponents.hour = dailyReminderHour
        dateComponents.minute = dailyReminderMinute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: dailyReminderIdentifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error = error {
                print("[NotificationService] Failed to schedule daily reminder: \(error)")
            }
            #endif
        }
    }
    
    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [dailyReminderIdentifier])
    }
    
    // MARK: - Gentle Inactivity Reminder (no pressure, guilt-free)
    
    /// Schedule a gentle reminder if user hasn't logged in a few days
    /// This is NOT about losing a streak - just a friendly check-in
    func scheduleGentleReminderIfInactive(daysSinceLastActivity: Int?) {
        guard gentleReminderEnabled, isAuthorized else { return }
        
        // Cancel any existing gentle reminder
        cancelGentleReminder()
        
        // Only schedule if they've been inactive for 3+ days
        guard let daysSince = daysSinceLastActivity, daysSince >= 3 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Whenever you're ready"
        content.body = gentleReminderMessages.randomElement() ?? "If today feels like a good day to notice something, we're here."
        content.sound = .default
        
        // Schedule for tomorrow at 10 AM
        var dateComponents = DateComponents()
        dateComponents.hour = 10
        dateComponents.minute = 0
        
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else { return }
        let tomorrowComponents = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        dateComponents.year = tomorrowComponents.year
        dateComponents.month = tomorrowComponents.month
        dateComponents.day = tomorrowComponents.day
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: gentleReminderIdentifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error = error {
                print("[NotificationService] Failed to schedule gentle reminder: \(error)")
            }
            #endif
        }
    }
    
    func cancelGentleReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [gentleReminderIdentifier])
    }
    
    // MARK: - Message Content
    
    private let dailyReminderMessages = [
        "Did something go well today? Capture it before you forget.",
        "Even a small win counts. What happened today?",
        "Notice a moment worth celebrating?",
        "One quick tap to catch a tiny win.",
        "What made you proud today? Save it!",
        "Progress, not perfection. Log one moment.",
        "Any positive moments to remember today?"
    ]
    
    private let gentleReminderMessages = [
        "If today feels like a good day to notice something, we're here.",
        "No pressure, just checking in. Any small wins lately?",
        "Pick up whenever you're ready. No catching up needed.",
        "When you have a moment, we'd love to help you notice something good."
    ]
}
