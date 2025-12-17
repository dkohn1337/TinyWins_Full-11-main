import SwiftUI

// MARK: - Insights Child Context Header

/// A compact header showing which child's data is being displayed.
/// Can optionally show a dropdown arrow for child selection.
///
/// ## Design Principles
/// - Compact: fits in a small horizontal strip
/// - Uses child's color tag for visual distinction
/// - Accessible: VoiceOver announces child name
/// - Optional dropdown affordance for child picker
struct InsightsChildContextHeader: View {
    @Environment(\.themeProvider) private var theme

    let child: Child
    var showDropdownArrow: Bool = false
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 10) {
                // Child avatar (small)
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    child.colorTag.color,
                                    child.colorTag.color.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .shadow(color: child.colorTag.color.opacity(0.3), radius: 2, y: 1)

                    Text(child.name.prefix(1).uppercased())
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }

                // Child name and context
                VStack(alignment: .leading, spacing: 2) {
                    Text(child.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryText)

                    Text("Viewing insights", tableName: "Insights")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }

                if showDropdownArrow {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.secondaryText)
                }

                Spacer()
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.vertical, 10)
            .background(theme.cardBackground)
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Viewing insights for \(child.name)", tableName: "Insights"))
        .accessibilityHint(showDropdownArrow ? Text("Double tap to change child", tableName: "Insights") : Text(""))
    }
}

// MARK: - Preview

#Preview("Child Context Header") {
    let repository = Repository.preview
    let child = repository.appData.children.first ?? Child(name: "Emma", colorTag: .coral)

    VStack(spacing: 0) {
        InsightsChildContextHeader(child: child)
        Spacer()
    }
    .withThemeProvider(ThemeProvider())
}
