import SwiftUI

struct ChildAvatar: View {
    let child: Child
    var size: CGFloat = 40
    
    var body: some View {
        Circle()
            .fill(child.colorTag.color)
            .frame(width: size, height: size)
            .overlay {
                Text(child.initials)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(.white)
            }
            .accessibilityLabel("\(child.name)'s avatar")
            .accessibilityAddTraits(.isImage)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 20) {
        ChildAvatar(child: Child(name: "Emma", colorTag: .purple), size: 30)
        ChildAvatar(child: Child(name: "Lucas", colorTag: .blue), size: 50)
        ChildAvatar(child: Child(name: "Sophia Grace", colorTag: .pink), size: 70)
    }
    .padding()
}
