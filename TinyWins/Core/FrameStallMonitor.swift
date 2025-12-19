import Foundation
import QuartzCore

#if DEBUG
/// Comprehensive frame stall monitor with context attribution.
/// Tracks screen changes, button taps, and navigation events to correlate
/// user actions with performance stalls.
///
/// Usage:
/// - Call `FrameStallMonitor.shared.start()` at app launch
/// - Use `.trackScreen("ScreenName")` modifier on screen roots
/// - Use `.stallActionName("action_name")` to name buttons
/// - Tab switches and navigation are tracked automatically
///
/// Logs:
/// - `🖱️ ACTION: xyz` - User action occurred
/// - `🧭 SCREEN: ScreenName` - Screen appeared
/// - `🧭 NAV: tab:today` - Navigation event
/// - `⚠️ FRAME STALL: 92 ms` - Stall detected with context
/// - `🧊 ACTION WINDOW STALL: 116 ms` - Stall within 500ms of action
/// - `✅ ACTION WINDOW OK` - No stall within 500ms of action
@MainActor
final class FrameStallMonitor: ObservableObject {
    static let shared = FrameStallMonitor()

    // MARK: - Action Types

    /// Categorizes user actions for correlation analysis
    enum ActionType: String, CustomStringConvertible {
        case buttonTap = "button_tap"
        case tabSwitch = "tab_switch"
        case presentSheet = "present_sheet"
        case dismissSheet = "dismiss_sheet"
        case presentFullscreen = "present_fullscreen"
        case dismissFullscreen = "dismiss_fullscreen"
        case exportShare = "export_share"
        case contextMenuOpen = "context_menu_open"
        case contextMenuSelect = "context_menu_select"
        case navigationPush = "nav_push"
        case navigationPop = "nav_pop"
        case pullToRefresh = "pull_to_refresh"
        case scrollEnd = "scroll_end"
        case textInput = "text_input"
        case pickerChange = "picker_change"
        case toggleChange = "toggle_change"
        case dragEnd = "drag_end"
        case longPress = "long_press"
        case swipeAction = "swipe_action"
        case unknown = "unknown"

        var description: String { rawValue }
    }

    // MARK: - Block Reasons

    /// Main thread block reason markers for deeper debugging
    enum BlockReason: String, CustomStringConvertible {
        case storeRecompute = "store_recompute"
        case viewBodyEval = "view_body_eval"
        case combinePublish = "combine_publish"
        case jsonEncode = "json_encode"
        case jsonDecode = "json_decode"
        case fileWrite = "file_write"
        case fileRead = "file_read"
        case firebaseWrite = "firebase_write"
        case firebaseRead = "firebase_read"
        case imageLoad = "image_load"
        case layoutPass = "layout_pass"
        case animationSetup = "animation_setup"
        case sheetBuild = "sheet_build"
        case listDiff = "list_diff"

        var description: String { rawValue }
    }

    // MARK: - Context

    struct Context: CustomStringConvertible {
        var screen: String = "unknown"
        var lastAction: String = "none"
        var lastActionType: ActionType = .unknown
        var lastActionId: String = "none"
        var lastNav: String = "none"
        var lastActionTs: CFTimeInterval = 0
        var lastNavTs: CFTimeInterval = 0
        var payloadSize: Int? = nil
        var payloadDescription: String? = nil
        var blockReason: BlockReason? = nil
        var blockReasonTs: CFTimeInterval = 0

        var description: String {
            var parts = ["screen=\(screen)", "action=\(lastAction)", "nav=\(lastNav)"]
            if lastActionId != "none" {
                // Short ID for readability (first 8 chars)
                let shortId = String(lastActionId.prefix(8))
                parts.append("aid=\(shortId)")
            }
            if lastActionType != .unknown {
                parts.append("type=\(lastActionType)")
            }
            if let size = payloadSize {
                parts.append("payload=\(size)")
            }
            if let desc = payloadDescription {
                parts.append("payload_desc=\(desc)")
            }
            if let reason = blockReason {
                parts.append("block=\(reason)")
            }
            return parts.joined(separator: " ")
        }

        /// Compact description for stall logs
        var stallDescription: String {
            var parts = ["screen=\(screen)", "action=\(lastAction)"]
            if lastActionType != .unknown && lastActionType != .buttonTap {
                parts.append("type=\(lastActionType)")
            }
            if let reason = blockReason {
                parts.append("block=\(reason)")
            }
            if let size = payloadSize {
                parts.append("payload=\(formatBytes(size))")
            }
            return parts.joined(separator: " ")
        }

        private func formatBytes(_ bytes: Int) -> String {
            if bytes < 1024 { return "\(bytes)B" }
            if bytes < 1024 * 1024 { return "\(bytes / 1024)KB" }
            return String(format: "%.1fMB", Double(bytes) / (1024 * 1024))
        }
    }

    // MARK: - State

    private var link: CADisplayLink?
    private var lastTick: CFTimeInterval = 0
    private var nominalFrameMs: Double = 16.67 // will be learned from device
    private var thresholdMs: Double = 33.0 // >33ms is noticeable jank

    private(set) var context = Context()

    // MARK: - Attribution Window

    /// Tracks the worst stall within a window after each action
    private var actionWindowId: UUID?
    private var actionWindowStart: CFTimeInterval = 0
    private var actionWindowName: String = ""
    private var actionWindowType: ActionType = .unknown
    private var actionWindowMaxStallMs: Double = 0
    private var actionWindowBlockReason: BlockReason? = nil
    private let actionWindowDuration: CFTimeInterval = 0.5 // 500ms

    // MARK: - Developer Settings

    /// Whether stall logging is enabled (controlled via Settings > Developer)
    @Published var isEnabled: Bool = false {
        didSet {
            if isEnabled {
                start()
            } else {
                stop()
            }
            // Persist to UserDefaults
            UserDefaults.standard.set(isEnabled, forKey: "FrameStallMonitor.isEnabled")
        }
    }

    // MARK: - Initialization

    private init() {
        // Load persisted preference
        isEnabled = UserDefaults.standard.bool(forKey: "FrameStallMonitor.isEnabled")
    }

    // MARK: - Lifecycle

    func start() {
        guard link == nil else { return }
        lastTick = 0
        link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link?.add(to: .main, forMode: .common)
        print("🎬 FrameStallMonitor started - watching for >\(Int(thresholdMs))ms stalls")
    }

    func stop() {
        link?.invalidate()
        link = nil
        lastTick = 0
        print("🎬 FrameStallMonitor stopped")
    }

    // MARK: - Context Markers

    /// Mark when a screen appears
    func setScreen(_ name: String) {
        guard isEnabled else { return }
        context.screen = name
        context.lastNav = "screen:\(name)"
        context.lastNavTs = CACurrentMediaTime()
        // Clear stale block reason when screen changes
        context.blockReason = nil
        print("🧭 SCREEN:", name)
    }

    /// Mark a navigation event (tab switch, push, pop)
    func markNavigation(_ name: String, type: ActionType? = nil) {
        guard isEnabled else { return }
        context.lastNav = name
        context.lastNavTs = CACurrentMediaTime()
        if let type = type {
            context.lastActionType = type
        }
        print("🧭 NAV:", name)
    }

    /// Mark a user action (button tap, gesture) - simple version
    func markAction(_ name: String) {
        markAction(name, type: .buttonTap)
    }

    /// Mark a user action with type classification
    func markAction(_ name: String, type: ActionType, payloadSize: Int? = nil, payloadDescription: String? = nil) {
        guard isEnabled else { return }
        let now = CACurrentMediaTime()
        let actionId = UUID()

        context.lastAction = name
        context.lastActionType = type
        context.lastActionId = actionId.uuidString
        context.lastActionTs = now
        context.payloadSize = payloadSize
        context.payloadDescription = payloadDescription
        context.blockReason = nil // Clear previous block reason

        let shortId = String(actionId.uuidString.prefix(8))
        var logParts = ["🖱️ ACTION:", name, "[\(shortId)]", "type=\(type)"]
        if let size = payloadSize {
            logParts.append("payload=\(context.stallDescription.contains("KB") ? "\(size/1024)KB" : "\(size)B")")
        }
        if let desc = payloadDescription {
            logParts.append("(\(desc))")
        }
        print(logParts.joined(separator: " "))

        // Start a fresh attribution window for this action
        actionWindowId = actionId
        actionWindowStart = now
        actionWindowName = name
        actionWindowType = type
        actionWindowMaxStallMs = 0
        actionWindowBlockReason = nil

        let id = actionWindowId
        Task { @MainActor in
            // Wait until the window closes, then log summary
            try? await Task.sleep(nanoseconds: UInt64(actionWindowDuration * 1_000_000_000))
            guard self.actionWindowId == id else { return }
            let shortActionId = String(id?.uuidString.prefix(8) ?? "none")
            if self.actionWindowMaxStallMs >= self.thresholdMs {
                var logMsg = "🧊 ACTION WINDOW STALL: \(Int(self.actionWindowMaxStallMs)) ms"
                logMsg += " aid=\(shortActionId)"
                logMsg += " action=\(self.actionWindowName)"
                logMsg += " type=\(self.actionWindowType)"
                logMsg += " screen=\(self.context.screen)"
                if let reason = self.actionWindowBlockReason {
                    logMsg += " block=\(reason)"
                }
                if let size = self.context.payloadSize {
                    logMsg += " payload=\(size)B"
                }
                print(logMsg)
            } else {
                print("✅ ACTION WINDOW OK:",
                      "aid=\(shortActionId)",
                      "action=\(self.actionWindowName)",
                      "type=\(self.actionWindowType)",
                      "screen=\(self.context.screen)")
            }
            self.actionWindowId = nil
        }
    }

    // MARK: - Typed Action Helpers

    /// Mark a tab switch action
    func markTabSwitch(from: String, to: String) {
        markAction("tab_\(from)_to_\(to)", type: .tabSwitch)
        markNavigation("tab:\(to)", type: .tabSwitch)
    }

    /// Mark sheet presentation
    func markPresentSheet(_ name: String) {
        markAction("present_\(name)", type: .presentSheet)
    }

    /// Mark sheet dismissal
    func markDismissSheet(_ name: String) {
        markAction("dismiss_\(name)", type: .dismissSheet)
    }

    /// Mark fullscreen cover presentation
    func markPresentFullscreen(_ name: String) {
        markAction("present_fullscreen_\(name)", type: .presentFullscreen)
    }

    /// Mark export/share action with payload info
    func markExportShare(itemCount: Int, estimatedBytes: Int) {
        markAction("export_share", type: .exportShare, payloadSize: estimatedBytes, payloadDescription: "\(itemCount) items")
    }

    /// Mark context menu open
    func markContextMenuOpen(_ target: String) {
        markAction("context_menu_\(target)", type: .contextMenuOpen)
    }

    /// Mark navigation push
    func markNavigationPush(_ destination: String) {
        markAction("push_\(destination)", type: .navigationPush)
        markNavigation("push:\(destination)", type: .navigationPush)
    }

    /// Mark navigation pop
    func markNavigationPop() {
        markAction("pop", type: .navigationPop)
        markNavigation("pop", type: .navigationPop)
    }

    // MARK: - Payload Size Tracking

    /// Set payload size for the current action (e.g., after JSON encoding)
    func setPayloadSize(_ bytes: Int, description: String? = nil) {
        guard isEnabled else { return }
        context.payloadSize = bytes
        context.payloadDescription = description
        if bytes > 10_000 { // Log large payloads
            let sizeStr = bytes < 1024 * 1024 ? "\(bytes/1024)KB" : String(format: "%.1fMB", Double(bytes)/(1024*1024))
            print("📦 PAYLOAD: \(sizeStr)", description ?? "")
        }
    }

    /// Clear payload after action completes
    func clearPayload() {
        context.payloadSize = nil
        context.payloadDescription = nil
    }

    // MARK: - Block Reason Markers

    /// Mark the start of a potentially blocking operation
    func markBlockReason(_ reason: BlockReason) {
        guard isEnabled else { return }
        context.blockReason = reason
        context.blockReasonTs = CACurrentMediaTime()
        // Also track in action window if active
        if actionWindowId != nil {
            actionWindowBlockReason = reason
        }
    }

    /// Clear block reason after operation completes
    func clearBlockReason() {
        context.blockReason = nil
    }

    /// Wrap a synchronous operation with block reason tracking
    func withBlockReason<T>(_ reason: BlockReason, operation: () -> T) -> T {
        markBlockReason(reason)
        defer { clearBlockReason() }
        return operation()
    }

    /// Wrap a synchronous throwing operation with block reason tracking
    func withBlockReason<T>(_ reason: BlockReason, operation: () throws -> T) rethrows -> T {
        markBlockReason(reason)
        defer { clearBlockReason() }
        return try operation()
    }

    // MARK: - Display Link Callback

    @objc private func tick(_ l: CADisplayLink) {
        if lastTick != 0 {
            let dt = l.timestamp - lastTick
            let dtMs = dt * 1000

            // Learn nominal frame time from early ticks
            if nominalFrameMs == 16.67, dtMs > 0, dtMs < 25 {
                nominalFrameMs = dtMs
            }

            if dtMs >= thresholdMs {
                let dropped = max(0, Int(round(dtMs / nominalFrameMs)) - 1)
                var logParts = ["⚠️ FRAME STALL:", "\(Int(dtMs)) ms", "dropped=\(dropped)"]

                // Add action ID if within action window
                if let id = actionWindowId {
                    let shortId = String(id.uuidString.prefix(8))
                    logParts.append("aid=\(shortId)")
                }

                // Use compact stall description
                logParts.append(context.stallDescription)

                print(logParts.joined(separator: " "))

                // Track block reason at time of stall
                if let reason = context.blockReason, actionWindowId != nil {
                    actionWindowBlockReason = reason
                }
            }

            // Track worst stall within action window
            if actionWindowId != nil {
                let now = l.timestamp
                if now - actionWindowStart <= actionWindowDuration {
                    actionWindowMaxStallMs = max(actionWindowMaxStallMs, dtMs)
                }
            }
        }
        lastTick = l.timestamp
    }

    // MARK: - Current Action ID (for external correlation)

    /// Get the current action ID (if within an action window)
    var currentActionId: String? {
        actionWindowId?.uuidString
    }

    /// Get short form of current action ID
    var currentActionIdShort: String? {
        actionWindowId.map { String($0.uuidString.prefix(8)) }
    }
}

// MARK: - Convenience Extensions

extension FrameStallMonitor {
    /// Log a stall-inducing operation with timing
    func measureBlock<T>(_ name: String, reason: BlockReason, operation: () -> T) -> T {
        let start = CACurrentMediaTime()
        markBlockReason(reason)
        let result = operation()
        let elapsed = (CACurrentMediaTime() - start) * 1000
        clearBlockReason()
        if elapsed > 16 { // Log operations taking more than 1 frame
            print("⏱️ BLOCK: \(name) took \(Int(elapsed))ms reason=\(reason)")
        }
        return result
    }
}
#endif
