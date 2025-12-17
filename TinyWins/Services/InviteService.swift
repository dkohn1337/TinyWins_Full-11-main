import Foundation
import UIKit

// MARK: - InviteService

/// Service for generating and sharing family invite codes.
/// Handles code generation, email formatting, and share sheet integration.
final class InviteService {

    // MARK: - Invite Code Generation

    /// Generate a random 6-character invite code.
    /// Excludes confusing characters like 0/O, 1/I/L.
    static func generateInviteCode() -> String {
        Family.randomInviteCode()
    }

    // MARK: - Share Content

    /// Generate share content for an invite code.
    /// - Parameters:
    ///   - inviteCode: The 6-character invite code
    ///   - parentName: Name of the parent sending the invite
    ///   - familyName: Name of the family
    /// - Returns: Formatted share text
    static func shareText(
        inviteCode: String,
        parentName: String,
        familyName: String
    ) -> String {
        """
        Join our family on Tiny Wins!

        \(parentName) has invited you to join "\(familyName)" on Tiny Wins - the app that helps you notice and celebrate your children's small wins together.

        Your invite code: \(inviteCode)

        To join:
        1. Download Tiny Wins from the App Store
        2. Sign in with Apple
        3. Tap "Join Family" and enter the code above

        Or tap this link to join:
        \(deepLink(for: inviteCode))

        This invitation expires in 7 days.
        """
    }

    /// Generate a shorter share text for messaging apps.
    /// - Parameters:
    ///   - inviteCode: The 6-character invite code
    ///   - parentName: Name of the parent sending the invite
    /// - Returns: Short formatted message
    static func shortShareText(
        inviteCode: String,
        parentName: String
    ) -> String {
        """
        \(parentName) invited you to Tiny Wins!

        Join code: \(inviteCode)

        Download the app and enter this code to sync our family's wins together.

        \(deepLink(for: inviteCode))
        """
    }

    // MARK: - Deep Links

    /// Generate a deep link URL for an invite code.
    /// - Parameter inviteCode: The 6-character invite code
    /// - Returns: Deep link URL string
    static func deepLink(for inviteCode: String) -> String {
        "tinywins://join?code=\(inviteCode)"
    }

    /// Generate a universal link URL for an invite code.
    /// - Parameter inviteCode: The 6-character invite code
    /// - Returns: Universal link URL string
    static func universalLink(for inviteCode: String) -> String {
        "https://tinywins.app/join/\(inviteCode)"
    }

    /// Parse an invite code from a deep link URL.
    /// - Parameter url: The URL to parse
    /// - Returns: The invite code if found, nil otherwise
    static func parseInviteCode(from url: URL) -> String? {
        // Handle custom scheme: tinywins://join?code=ABC123
        if url.scheme == "tinywins" && url.host == "join" {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            return components?.queryItems?.first(where: { $0.name == "code" })?.value
        }

        // Handle universal link: https://tinywins.app/join/ABC123
        if url.host == "tinywins.app" && url.pathComponents.contains("join") {
            if let codeIndex = url.pathComponents.firstIndex(of: "join"),
               url.pathComponents.count > codeIndex + 1 {
                return url.pathComponents[codeIndex + 1]
            }
        }

        return nil
    }

    // MARK: - Email Invite

    /// Generate a formatted HTML email for invite.
    /// - Parameters:
    ///   - inviteCode: The 6-character invite code
    ///   - parentName: Name of the parent sending the invite
    ///   - familyName: Name of the family
    /// - Returns: HTML email body
    static func emailHTML(
        inviteCode: String,
        parentName: String,
        familyName: String
    ) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { text-align: center; padding: 20px 0; }
                .logo { font-size: 48px; margin-bottom: 10px; }
                h1 { color: #2563eb; margin: 0; font-size: 24px; }
                .code-box { background: #f3f4f6; border-radius: 12px; padding: 20px; text-align: center; margin: 20px 0; }
                .code { font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #1f2937; font-family: monospace; }
                .steps { background: #fefefe; border: 1px solid #e5e7eb; border-radius: 12px; padding: 20px; margin: 20px 0; }
                .step { display: flex; align-items: flex-start; margin-bottom: 12px; }
                .step-number { background: #2563eb; color: white; width: 24px; height: 24px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: bold; margin-right: 12px; flex-shrink: 0; }
                .button { display: inline-block; background: #2563eb; color: white; padding: 14px 28px; border-radius: 8px; text-decoration: none; font-weight: 600; margin: 20px 0; }
                .footer { color: #6b7280; font-size: 14px; text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #e5e7eb; }
            </style>
        </head>
        <body>
            <div class="header">
                <div class="logo">⭐</div>
                <h1>Join Our Family on Tiny Wins</h1>
            </div>

            <p>Hi there!</p>

            <p><strong>\(parentName)</strong> has invited you to join <strong>"\(familyName)"</strong> on Tiny Wins - the app that helps you notice and celebrate your children's small wins together.</p>

            <div class="code-box">
                <p style="margin: 0 0 10px 0; color: #6b7280; font-size: 14px;">Your invite code:</p>
                <div class="code">\(inviteCode)</div>
            </div>

            <div class="steps">
                <p style="margin: 0 0 15px 0; font-weight: 600;">To join:</p>
                <div class="step">
                    <span class="step-number">1</span>
                    <span>Download Tiny Wins from the App Store</span>
                </div>
                <div class="step">
                    <span class="step-number">2</span>
                    <span>Sign in with Apple</span>
                </div>
                <div class="step">
                    <span class="step-number">3</span>
                    <span>Tap "Join Family" and enter the code above</span>
                </div>
            </div>

            <div style="text-align: center;">
                <a href="\(deepLink(for: inviteCode))" class="button">Join Family</a>
            </div>

            <div class="footer">
                <p>This invitation expires in 7 days.</p>
                <p>- The Tiny Wins Team</p>
            </div>
        </body>
        </html>
        """
    }

    /// Email subject line for invite.
    static func emailSubject(familyName: String) -> String {
        "Join \(familyName) on Tiny Wins"
    }

    // MARK: - Share Sheet

    /// Present a share sheet with invite options.
    /// - Parameters:
    ///   - inviteCode: The 6-character invite code
    ///   - parentName: Name of the parent sending the invite
    ///   - familyName: Name of the family
    ///   - from: The view controller to present from
    @MainActor
    static func presentShareSheet(
        inviteCode: String,
        parentName: String,
        familyName: String,
        from viewController: UIViewController
    ) {
        let shareText = shortShareText(inviteCode: inviteCode, parentName: parentName)
        let url = URL(string: universalLink(for: inviteCode))!

        let items: [Any] = [shareText, url]

        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        // Exclude activities that don't make sense for invites
        activityVC.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .openInIBooks,
            .print,
            .saveToCameraRoll
        ]

        // For iPad
        activityVC.popoverPresentationController?.sourceView = viewController.view
        activityVC.popoverPresentationController?.sourceRect = CGRect(
            x: viewController.view.bounds.midX,
            y: viewController.view.bounds.midY,
            width: 0,
            height: 0
        )

        viewController.present(activityVC, animated: true)
    }
}

// MARK: - Invite Item for Share Sheet

/// A custom activity item source that provides different content for different share targets.
final class InviteActivityItem: NSObject, UIActivityItemSource {
    let inviteCode: String
    let parentName: String
    let familyName: String

    init(inviteCode: String, parentName: String, familyName: String) {
        self.inviteCode = inviteCode
        self.parentName = parentName
        self.familyName = familyName
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return InviteService.shortShareText(inviteCode: inviteCode, parentName: parentName)
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        guard let activityType = activityType else {
            return InviteService.shortShareText(inviteCode: inviteCode, parentName: parentName)
        }

        // Use HTML for email
        if activityType == .mail {
            return InviteService.emailHTML(
                inviteCode: inviteCode,
                parentName: parentName,
                familyName: familyName
            )
        }

        // Short text for messaging
        if activityType == .message || activityType.rawValue.contains("whatsapp") {
            return InviteService.shortShareText(inviteCode: inviteCode, parentName: parentName)
        }

        // Full text for others
        return InviteService.shareText(
            inviteCode: inviteCode,
            parentName: parentName,
            familyName: familyName
        )
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        return InviteService.emailSubject(familyName: familyName)
    }
}
