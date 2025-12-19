import SwiftUI

// MARK: - Progress Ring Components
// Components for displaying progress in circular formats

/// Number that animates when value changes
struct CountingNumberView: View {
    let target: Int
    let font: Font
    let color: Color

    @State private var displayed: Int = 0

    init(target: Int, size: CGFloat = 88, weight: Font.Weight = .black, color: Color = .primary) {
        self.target = target
        self.font = .system(size: size, weight: weight, design: .rounded)
        self.color = color
    }

    var body: some View {
        Text("\(displayed)")
            .font(font)
            .foregroundColor(color)
            .onAppear {
                animateCount(from: 0)
            }
            .onChange(of: target) { oldValue, newValue in
                animateCount(from: displayed)
            }
    }

    private func animateCount(from start: Int) {
        let steps = 30
        let difference = target - start
        guard difference != 0 else { return }

        let stepValue = Double(difference) / Double(steps)

        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.025) {
                if i == steps - 1 {
                    displayed = target
                } else {
                    displayed = start + Int(Double(i + 1) * stepValue)
                }
            }
        }
    }
}

/// Large animated progress ring with center content
struct GiantProgressRing: View {
    @Environment(\.theme) private var theme
    let progress: CGFloat // 0.0 to 1.0
    let current: Int
    let total: Int
    let color: Color
    let size: CGFloat
    let strokeWidth: CGFloat

    @State private var animatedProgress: CGFloat = 0

    init(progress: CGFloat, current: Int, total: Int, color: Color, size: CGFloat = 260, strokeWidth: CGFloat = 28) {
        self.progress = progress
        self.current = current
        self.total = total
        self.color = color
        self.size = size
        self.strokeWidth = strokeWidth
    }

    private var proximityMessage: String? {
        let remaining = total - current
        switch remaining {
        case 1: return "Only 1 more!"
        case 2: return "Just 2 more!"
        case 3: return "Almost there!"
        default: return nil
        }
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(theme.textDisabled.opacity(0.15), lineWidth: strokeWidth)
                .frame(width: size, height: size)

            // Progress ring with gradient
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [
                            color,
                            color.opacity(0.7),
                            color.opacity(0.5),
                            color
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            // Milestone markers
            ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { milestone in
                Circle()
                    .fill(animatedProgress >= milestone ? color : theme.textDisabled.opacity(0.3))
                    .frame(width: 16, height: 16)
                    .shadow(color: animatedProgress >= milestone ? color.opacity(0.5) : .clear, radius: 8)
                    .offset(y: -size / 2)
                    .rotationEffect(.degrees(milestone * 360 - 90))
            }

            // Center content
            VStack(spacing: 8) {
                CountingNumberView(target: current, size: 88, color: color)

                Text("of \(total)")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(theme.textSecondary)

                if let message = proximityMessage {
                    Text(message)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.15))
                        )
                        .padding(.top, 8)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Preview

#Preview("Progress Ring") {
    GiantProgressRing(progress: 0.7, current: 7, total: 10, color: .purple)
        .padding()
}
