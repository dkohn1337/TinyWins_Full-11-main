import SwiftUI

/// A view for picking a reward template or creating a custom reward
struct RewardTemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeProvider: ThemeProvider

    let child: Child
    let onTemplateSelected: (RewardTemplate) -> Void
    let onCreateCustom: () -> Void

    // Group templates by category, filtered by age
    private var templatesByCategory: [(category: RewardTemplate.Category, templates: [RewardTemplate])] {
        let ageAppropriate = RewardTemplate.templates(forAge: child.age)

        // Group by category and filter out empty categories
        return RewardTemplate.Category.allCases.compactMap { category in
            let templates = ageAppropriate.filter { $0.category == category }
            return templates.isEmpty ? nil : (category, templates)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero Header
                    heroHeader

                    // Quick Custom Option at top for power users
                    quickCustomButton
                        .padding(.horizontal)

                    // Categories
                    ForEach(templatesByCategory, id: \.category) { categoryGroup in
                        CategorySection(
                            category: categoryGroup.category,
                            templates: categoryGroup.templates,
                            childColor: child.colorTag.color
                        ) { template in
                            AnalyticsService.shared.log(.custom("reward_template_used", [
                                "template_id": template.id,
                                "category": template.category.rawValue,
                                "child_id": child.id.uuidString
                            ]))
                            onTemplateSelected(template)
                            dismiss()
                        }
                    }

                    // Completeness footer
                    completenessFooter

                    // Bottom spacing
                    Spacer().frame(height: 24)
                }
            }
            .background(Color(.systemGroupedBackground))
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

    // MARK: - Hero Header

    private var heroHeader: some View {
        VStack(spacing: 16) {
            // Animated gift icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [child.colorTag.color.opacity(0.2), child.colorTag.color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "gift.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [child.colorTag.color, child.colorTag.color.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("What's \(child.name) working toward?")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("Pick something meaningful. Experiences create the best memories.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 24)
    }

    // MARK: - Completeness Footer

    private var completenessFooter: some View {
        let totalCount = templatesByCategory.reduce(0) { $0 + $1.templates.count }
        let ageText = child.age.map { "age \($0)" } ?? "all ages"

        return HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.green)
            Text("Showing all \(totalCount) goals for \(ageText)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Quick Custom Button

    private var quickCustomButton: some View {
        Button {
            AnalyticsService.shared.log(.custom("reward_created_custom", [
                "source": "quick_button",
                "child_id": child.id.uuidString
            ]))
            onCreateCustom()
            dismiss()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(child.colorTag.color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundColor(child.colorTag.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Create your own")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Custom name, stars & timeline")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(child.colorTag.color.opacity(0.3), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Section

private struct CategorySection: View {
    let category: RewardTemplate.Category
    let templates: [RewardTemplate]
    let childColor: Color
    let onSelect: (RewardTemplate) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.15))
                        .frame(width: 32, height: 32)

                    Image(systemName: category.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(category.color)
                }

                Text(category.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(templates.count)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            // Horizontal scroll of templates
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(templates) { template in
                        CompactTemplateCard(
                            template: template,
                            categoryColor: category.color,
                            onTap: { onSelect(template) }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Compact Template Card (for horizontal scroll)

private struct CompactTemplateCard: View {
    let template: RewardTemplate
    let categoryColor: Color
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                // Icon with colored background
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [categoryColor.opacity(0.2), categoryColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)

                        Image(systemName: template.icon)
                            .font(.system(size: 28))
                            .foregroundColor(categoryColor)
                    }

                    // Popular/Quick Win badge
                    if template.isPopular || template.isQuickWin {
                        HStack(spacing: 2) {
                            Image(systemName: template.isPopular ? "heart.fill" : "bolt.fill")
                                .font(.system(size: 8))
                            Text(template.isPopular ? "Popular" : "Quick")
                                .font(.system(size: 8, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(template.isPopular ? Color.pink : Color.orange)
                        .cornerRadius(6)
                        .offset(x: 8, y: -4)
                    }
                }

                // Name
                Text(template.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 40)

                // Info badges
                HStack(spacing: 6) {
                    // Stars
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                        Text("\(template.defaultPoints)")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.secondary)
                    }

                    Text("•")
                        .font(.caption2)
                        .foregroundColor(Color(.systemGray4))

                    // Days
                    HStack(spacing: 2) {
                        Image(systemName: "calendar")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Text("\(template.defaultDurationDays)d")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 130)
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Preview

#Preview {
    RewardTemplatePickerView(
        child: Child(name: "Emma", age: 7, colorTag: .purple),
        onTemplateSelected: { template in
            print("Selected: \(template.name)")
        },
        onCreateCustom: {
            print("Create custom")
        }
    )
    .environmentObject(ThemeProvider())
}
