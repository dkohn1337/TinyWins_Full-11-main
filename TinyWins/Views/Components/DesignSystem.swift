import SwiftUI

// MARK: - App Colors (Legacy - Deprecated)
// NOTE: Use ThemeProvider via environment instead for theme-aware colors

struct AppColors {
    // Primary palette - DEPRECATED: Use theme.accentColor instead
    static let primary = Color.blue

    // Semantic colors - DEPRECATED: Use theme.positiveColor, theme.challengeColor, etc.
    static let positive = Color(red: 0.3, green: 0.75, blue: 0.4) // Soft green
    static let challenge = Color(red: 1.0, green: 0.6, blue: 0.3) // Soft orange
    static let negative = challenge // Alias for challenge
    static let routine = Color(red: 0.4, green: 0.6, blue: 0.9) // Soft blue

    // Plus tier color
    static let plus = Color(red: 0.6, green: 0.4, blue: 0.9) // Purple for premium

    // Icon backgrounds (limited palette)
    static let iconBackgrounds: [Color] = [
        Color(red: 0.9, green: 0.95, blue: 1.0),   // Light blue
        Color(red: 0.9, green: 1.0, blue: 0.9),    // Light green
        Color(red: 1.0, green: 0.95, blue: 0.85),  // Light orange
        Color(red: 1.0, green: 0.98, blue: 0.85),  // Light yellow
        Color(red: 0.95, green: 0.9, blue: 1.0),   // Light purple
    ]

    // Gradients for child-facing screens
    static func childGradient(for color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color.opacity(0.3), color.opacity(0.1), Color(.systemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // Star gradient - Legacy version (DEPRECATED: Use starGradient(theme:) instead)
    static let starGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.8, blue: 0.2), Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Star gradient - Theme-aware version
    @MainActor
    static func starGradient(theme: ThemeProvider) -> LinearGradient {
        let starColor = theme.starColor
        return LinearGradient(
            colors: [starColor, starColor.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - App Styles

struct AppStyles {
    static let cardCornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 12
    static let iconCornerRadius: CGFloat = 10
    
    static let cardShadow = Color.black.opacity(0.08)
    static let cardShadowRadius: CGFloat = 8
    
    static let childFriendlyFont = Font.system(.title2, design: .rounded, weight: .semibold)
    static let childFriendlyLargeFont = Font.system(.largeTitle, design: .rounded, weight: .bold)
}

// MARK: - Styled Icon View

struct StyledIcon: View {
    let systemName: String
    let color: Color
    var size: CGFloat = 24
    var backgroundSize: CGFloat = 44
    var isCircle: Bool = false
    
    var body: some View {
        ZStack {
            if isCircle {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: backgroundSize, height: backgroundSize)
            } else {
                RoundedRectangle(cornerRadius: AppStyles.iconCornerRadius)
                    .fill(color.opacity(0.15))
                    .frame(width: backgroundSize, height: backgroundSize)
            }
            
            Image(systemName: systemName)
                .font(.system(size: size))
                .foregroundColor(color)
        }
    }
}

// MARK: - App Icon View

/// Consistent app icon used across the app (More tab, About, etc.)
struct AppIconView: View {
    var size: CGFloat = 60
    var cornerRadius: CGFloat? = nil

    private var computedCornerRadius: CGFloat {
        cornerRadius ?? (size * 0.267) // ~16/60 ratio for iOS-style app icons
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: computedCornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.55, green: 0.35, blue: 0.95), // Purple
                            Color(red: 0.35, green: 0.55, blue: 0.95)  // Blue
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: Color(red: 0.55, green: 0.35, blue: 0.95).opacity(0.4), radius: size * 0.2, y: size * 0.1)

            Image(systemName: "star.fill")
                .font(.system(size: size * 0.47))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Card Container

struct CardContainer<Content: View>: View {
    let content: Content
    var backgroundColor: Color = Color(.systemBackground)
    
    init(backgroundColor: Color = Color(.systemBackground), @ViewBuilder content: () -> Content) {
        self.backgroundColor = backgroundColor
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(backgroundColor)
            .cornerRadius(AppStyles.cardCornerRadius)
            .shadow(color: AppStyles.cardShadow, radius: AppStyles.cardShadowRadius, y: 2)
    }
}

// MARK: - Toast Banner

// MARK: - Toast Category
enum ToastCategory {
    case routine
    case positive
    case challenge
    case neutral

    /// Get theme-aware color for this toast category
    @MainActor
    func color(from theme: ThemeProvider) -> Color {
        switch self {
        case .routine: return theme.routineColor
        case .positive: return theme.positiveColor
        case .challenge: return theme.challengeColor
        case .neutral: return Color(.systemGray)
        }
    }

    /// Legacy color accessor (falls back to default theme colors)
    var color: Color {
        switch self {
        case .routine: return AppColors.routine
        case .positive: return AppColors.positive
        case .challenge: return AppColors.challenge
        case .neutral: return Color(.systemGray)
        }
    }

    var verb: String {
        switch self {
        case .routine, .positive, .neutral: return "Added"
        case .challenge: return "Noted"
        }
    }
}

struct ToastBanner: View {
    let message: String
    let icon: String
    var category: ToastCategory = .positive
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(category.color)
        )
        .shadow(color: category.color.opacity(0.25), radius: 6, y: 2)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let icon: String
    var category: ToastCategory = .positive
    var duration: Double = 2.5
    
    // Use ID to ensure proper cleanup
    @State private var dismissTask: Task<Void, Never>?
    
    func body(content: Content) -> some View {
        ZStack {
            content

            VStack {
                if isShowing {
                    ToastBanner(message: message, icon: icon, category: category) {
                        dismiss()
                    }
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.9).combined(with: .opacity).combined(with: .move(edge: .top)),
                            removal: .opacity
                        )
                    )
                    .padding(.top, 60)
                    .zIndex(100)
                }

                Spacer()
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isShowing)
        }
        .onChange(of: isShowing) { oldValue, newValue in
            if newValue {
                // Cancel any existing task
                dismissTask?.cancel()
                
                // Start new dismiss timer
                dismissTask = Task {
                    try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                    if !Task.isCancelled {
                        await MainActor.run {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private func dismiss() {
        dismissTask?.cancel()
        withAnimation {
            isShowing = false
        }
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, message: String, icon: String = "checkmark.circle.fill", category: ToastCategory = .positive) -> some View {
        modifier(ToastModifier(isShowing: isShowing, message: message, icon: icon, category: category))
    }
    
    // Legacy support with color parameter
    func toast(isShowing: Binding<Bool>, message: String, icon: String = "checkmark.circle.fill", color: Color) -> some View {
        let category: ToastCategory = {
            if color == AppColors.positive { return .positive }
            if color == AppColors.challenge { return .challenge }
            if color == AppColors.routine { return .routine }
            return .neutral
        }()
        return modifier(ToastModifier(isShowing: isShowing, message: message, icon: icon, category: category))
    }
}

// MARK: - Stars Display

struct StarsDisplay: View {
    let count: Int
    let total: Int
    var size: CGFloat = 16
    var showLabel: Bool = true
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: size))
                .foregroundStyle(AppColors.starGradient)
            
            if showLabel {
                Text("\(count) of \(total) stars")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("\(count)/\(total)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Points Badge

struct PointsBadge: View {
    let points: Int
    var useStars: Bool = false
    var size: Font = .subheadline
    
    var body: some View {
        HStack(spacing: 4) {
            Text(points >= 0 ? "+\(points)" : "\(points)")
                .font(size)
                .fontWeight(.semibold)
                .foregroundColor(points >= 0 ? AppColors.positive : AppColors.challenge)
            
            if useStars {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    let colors: [Color] = [.yellow, .orange, .pink, .purple, .blue, .green]
    
    struct ConfettiParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var rotation: Double
        var scale: CGFloat
        var opacity: Double
        var color: Color
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Rectangle()
                        .fill(particle.color)
                        .frame(width: 8, height: 12)
                        .rotationEffect(.degrees(particle.rotation))
                        .scaleEffect(particle.scale)
                        .opacity(particle.opacity)
                        .position(x: particle.x, y: particle.y)
                }
            }
            .onAppear {
                createConfetti(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func createConfetti(in size: CGSize) {
        for _ in 0..<50 {
            let particle = ConfettiParticle(
                x: size.width / 2 + CGFloat.random(in: -50...50),
                y: size.height / 3,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.5...1.2),
                opacity: 1,
                color: colors.randomElement()!
            )
            particles.append(particle)
        }
        
        // Animate particles
        for i in particles.indices {
            let targetX = CGFloat.random(in: 0...size.width)
            let targetY = size.height + 50
            
            withAnimation(.easeOut(duration: Double.random(in: 1.5...2.5))) {
                particles[i].x = targetX
                particles[i].y = targetY
                particles[i].rotation = Double.random(in: 0...720)
                particles[i].opacity = 0
            }
        }
    }
}

// MARK: - Milestone Celebration Modifier

struct MilestoneCelebrationModifier: ViewModifier {
    @Binding var isShowing: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isShowing {
                ConfettiView()
                    .ignoresSafeArea()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            isShowing = false
                        }
                    }
            }
        }
    }
}

extension View {
    func milestoneCelebration(isShowing: Binding<Bool>) -> some View {
        modifier(MilestoneCelebrationModifier(isShowing: isShowing))
    }
}

// MARK: - Child Friendly Text Styles

extension Text {
    func childFriendlyTitle() -> some View {
        self.font(AppStyles.childFriendlyLargeFont)
    }
    
    func childFriendlyHeadline() -> some View {
        self.font(AppStyles.childFriendlyFont)
    }
}

// MARK: - Signature Canvas View

struct SignatureCanvasView: View {
    @Binding var signatureImage: UIImage?
    @State private var paths: [Path] = []
    @State private var currentPath = Path()
    
    var body: some View {
        VStack(spacing: 0) {
            Canvas { context, size in
                // Draw completed paths
                for path in paths {
                    context.stroke(path, with: .color(.primary), lineWidth: 3)
                }
                // Draw current path
                context.stroke(currentPath, with: .color(.primary), lineWidth: 3)
            }
            .frame(height: 150)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let point = value.location
                        if currentPath.isEmpty {
                            currentPath.move(to: point)
                        } else {
                            currentPath.addLine(to: point)
                        }
                    }
                    .onEnded { _ in
                        paths.append(currentPath)
                        currentPath = Path()
                    }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            
            HStack {
                Button(action: clearSignature) {
                    Label("Clear", systemImage: "arrow.counterclockwise")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("Sign with your finger")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
    }
    
    private func clearSignature() {
        paths.removeAll()
        currentPath = Path()
        signatureImage = nil
    }
    
    func captureSignature(size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.systemGray6.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            UIColor.label.setStroke()
            let cgContext = context.cgContext
            cgContext.setLineWidth(3)
            cgContext.setLineCap(.round)
            
            for path in paths {
                cgContext.addPath(path.cgPath)
            }
            cgContext.strokePath()
        }
    }
}

// MARK: - Time Range Enum

enum InsightTimeRange: String, CaseIterable {
    case thisWeek = "This Week"
    case lastWeek = "Last Week"
    case last30Days = "Last 30 Days"
    
    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return (startOfWeek, now)
        case .lastWeek:
            let startOfThisWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let startOfLastWeek = calendar.date(byAdding: .day, value: -7, to: startOfThisWeek)!
            return (startOfLastWeek, startOfThisWeek)
        case .last30Days:
            let start = calendar.date(byAdding: .day, value: -30, to: now)!
            return (start, now)
        }
    }
}

// MARK: - Triangle Shape (for tooltips)

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview("Toast Banner") {
    VStack {
        ToastBanner(message: "Added 'Shared toys' (+2 stars)", icon: "checkmark.circle.fill") {}
        ToastBanner(message: "Noted 'Shouting' (-3 stars)", icon: "checkmark.circle.fill", category: .challenge) {}
    }
    .padding()
}

#Preview("Styled Icons") {
    HStack(spacing: 20) {
        StyledIcon(systemName: "star.fill", color: .yellow)
        StyledIcon(systemName: "hand.thumbsup.fill", color: AppColors.positive)
        StyledIcon(systemName: "exclamationmark.triangle.fill", color: AppColors.challenge, isCircle: true)
    }
}
