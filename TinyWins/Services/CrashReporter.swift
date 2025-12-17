import Foundation
import os.log

#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics
#endif

// MARK: - Crash Reporter

/// Centralized crash reporting and non-fatal error logging.
/// Supports Firebase Crashlytics when available, with fallback to os_log.
/// Ensures no sensitive data (emails, names, IDs) is logged.
enum CrashReporter {

    // MARK: - Logger

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.tinywins", category: "CrashReporter")

    // MARK: - Initialization

    /// Initialize crash reporting. Call once at app startup after Firebase configuration.
    static func initialize() {
        #if canImport(FirebaseCrashlytics)
        // Crashlytics is auto-initialized by Firebase. Just log that we're ready.
        #if DEBUG
        // Disable crash collection in debug builds to avoid noise
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
        logger.info("CrashReporter: Crashlytics disabled in DEBUG")
        #else
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        logger.info("CrashReporter: Crashlytics enabled")
        #endif
        #else
        logger.info("CrashReporter: Crashlytics SDK not available, using os_log fallback")
        #endif
    }

    // MARK: - Non-Fatal Error Logging

    /// Log a non-fatal error for tracking without crashing.
    /// - Parameters:
    ///   - error: The error to log
    ///   - context: Additional context about where/why the error occurred
    ///   - file: Source file (auto-captured)
    ///   - function: Function name (auto-captured)
    ///   - line: Line number (auto-captured)
    static func logNonFatal(
        _ error: Error,
        context: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let sanitizedContext = sanitize(context)
        let fileName = (file as NSString).lastPathComponent

        #if canImport(FirebaseCrashlytics)
        #if !DEBUG
        // Add context as custom key
        Crashlytics.crashlytics().setCustomValue(sanitizedContext, forKey: "error_context")
        Crashlytics.crashlytics().setCustomValue("\(fileName):\(line)", forKey: "error_location")
        Crashlytics.crashlytics().setCustomValue(function, forKey: "error_function")

        // Record the error
        Crashlytics.crashlytics().record(error: error)
        #endif
        #endif

        // Always log to os_log for debugging
        logger.error("[\(sanitizedContext)] \(error.localizedDescription) at \(fileName):\(line)")
    }

    /// Log a non-fatal error with a custom domain and code.
    /// - Parameters:
    ///   - domain: Error domain (e.g., "StoreKit", "CloudBackup")
    ///   - code: Numeric error code
    ///   - message: Descriptive message (will be sanitized)
    ///   - underlyingError: Optional underlying error
    static func logNonFatal(
        domain: String,
        code: Int,
        message: String,
        underlyingError: Error? = nil
    ) {
        let sanitizedMessage = sanitize(message)

        var userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: sanitizedMessage
        ]

        if let underlying = underlyingError {
            userInfo[NSUnderlyingErrorKey] = underlying
        }

        let error = NSError(domain: domain, code: code, userInfo: userInfo)
        logNonFatal(error, context: domain)
    }

    // MARK: - StoreKit Specific Logging

    /// Log a StoreKit failure without exposing sensitive transaction data.
    /// - Parameters:
    ///   - operation: The operation that failed (e.g., "purchase", "restore", "loadProducts")
    ///   - error: The error that occurred
    ///   - productId: Optional product ID (safe to log)
    static func logStoreKitFailure(
        operation: String,
        error: Error,
        productId: String? = nil
    ) {
        var context = "StoreKit.\(operation)"
        if let productId = productId {
            context += " product=\(productId)"
        }

        // Log specific StoreKit error codes for better debugging
        let errorCode: Int
        let errorDomain = "StoreKit"

        if let skError = error as? StoreKitError {
            switch skError {
            case .unknown:
                errorCode = 0
            case .userCancelled:
                // Don't log user cancellations as errors
                logger.info("StoreKit: User cancelled \(operation)")
                return
            case .networkError:
                errorCode = 1
            case .systemError:
                errorCode = 2
            case .notAvailableInStorefront:
                errorCode = 3
            case .notEntitled:
                errorCode = 4
            case .unsupported:
                errorCode = 5
            @unknown default:
                errorCode = 999
            }
        } else {
            errorCode = (error as NSError).code
        }

        logNonFatal(
            domain: errorDomain,
            code: errorCode,
            message: "StoreKit \(operation) failed",
            underlyingError: error
        )
    }

    /// Log a subscription verification failure.
    /// - Parameters:
    ///   - reason: Why verification failed
    ///   - productId: The product ID being verified
    static func logSubscriptionVerificationFailure(reason: String, productId: String) {
        logNonFatal(
            domain: "StoreKit.Verification",
            code: 100,
            message: "Verification failed: \(reason) for product \(productId)"
        )
    }

    // MARK: - Custom Keys (for crash context)

    /// Set a custom key-value pair for crash context.
    /// Value will be sanitized to remove sensitive data.
    /// - Parameters:
    ///   - key: The key name
    ///   - value: The value (will be sanitized)
    static func setCustomKey(_ key: String, value: String) {
        let sanitizedValue = sanitize(value)

        #if canImport(FirebaseCrashlytics)
        #if !DEBUG
        Crashlytics.crashlytics().setCustomValue(sanitizedValue, forKey: key)
        #endif
        #endif
    }

    /// Set the user identifier for crash reports.
    /// Only stores a hashed/anonymized version, never the actual ID.
    /// - Parameter userId: The user ID to hash and store
    static func setUserId(_ userId: String?) {
        guard let userId = userId else {
            #if canImport(FirebaseCrashlytics)
            #if !DEBUG
            Crashlytics.crashlytics().setUserID("")
            #endif
            #endif
            return
        }

        // Hash the user ID for privacy
        let hashedId = userId.hashValue.description

        #if canImport(FirebaseCrashlytics)
        #if !DEBUG
        Crashlytics.crashlytics().setUserID(hashedId)
        #endif
        #endif
    }

    // MARK: - Breadcrumbs

    /// Log a breadcrumb for crash context (helps understand what led to a crash).
    /// - Parameter message: The breadcrumb message (will be sanitized)
    static func log(_ message: String) {
        let sanitizedMessage = sanitize(message)

        #if canImport(FirebaseCrashlytics)
        #if !DEBUG
        Crashlytics.crashlytics().log(sanitizedMessage)
        #endif
        #endif

        logger.debug("\(sanitizedMessage)")
    }

    // MARK: - Sensitive Data Sanitization

    /// Patterns that indicate sensitive data
    private static let sensitivePatterns: [(pattern: String, replacement: String)] = [
        // Email addresses
        (#"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"#, "[EMAIL]"),
        // UUIDs (child IDs, user IDs, etc.)
        (#"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"#, "[UUID]"),
        // Phone numbers (various formats)
        (#"\+?[\d\s\-\(\)]{10,}"#, "[PHONE]"),
        // Firebase user IDs (typically 28 alphanumeric chars)
        (#"\b[a-zA-Z0-9]{28}\b"#, "[USER_ID]"),
        // Potential names (capitalized words that might be names - conservative)
        (#"child(ren)?'?s?\s+name[:\s]+\w+"#, "child name: [NAME]"),
    ]

    /// Sanitize a string by removing sensitive data patterns.
    /// - Parameter input: The string to sanitize
    /// - Returns: Sanitized string with sensitive data replaced
    private static func sanitize(_ input: String) -> String {
        var result = input

        for (pattern, replacement) in sensitivePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(result.startIndex..., in: result)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: replacement)
            }
        }

        return result
    }
}

// MARK: - StoreKit Error Extension

import StoreKit

extension StoreKitError: @retroactive CustomNSError {
    public static var errorDomain: String { "StoreKitError" }

    public var errorCode: Int {
        switch self {
        case .unknown: return 0
        case .userCancelled: return 1
        case .networkError: return 2
        case .systemError: return 3
        case .notAvailableInStorefront: return 4
        case .notEntitled: return 5
        case .unsupported: return 6
        @unknown default: return 999
        }
    }

    public var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: localizedDescription]
    }
}
