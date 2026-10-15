import SwiftUI
import InklingCore

/// Colours and the few shared building blocks. Everything is semantic, so dark mode needs no special cases.
enum Theme {
    static let background = Color(.systemGroupedBackground)
    static let card = Color(.secondarySystemGroupedBackground)
    static let line = Color(.separator).opacity(0.5)
    static let side: CGFloat = 20
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.line, lineWidth: 0.5))
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}

extension Mood {
    /// A weather symbol per mood: stormy at the bottom, bright sun at the top.
    var symbol: String {
        switch self {
        case .rough: "cloud.bolt.rain.fill"
        case .low: "cloud.rain.fill"
        case .okay: "cloud.fill"
        case .good: "cloud.sun.fill"
        case .great: "sun.max.fill"
        }
    }

    var color: Color {
        switch self {
        case .rough: Color(red: 0.84, green: 0.30, blue: 0.32)
        case .low: Color(red: 0.92, green: 0.55, blue: 0.22)
        case .okay: Color(red: 0.55, green: 0.58, blue: 0.66)
        case .good: Color(red: 0.20, green: 0.62, blue: 0.62)
        case .great: Color(red: 0.25, green: 0.66, blue: 0.38)
        }
    }
}

struct TagChip: View {
    let tag: String
    var body: some View {
        Text("#\(tag)")
            .font(.caption.weight(.medium))
            .foregroundStyle(.tint)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(.tint.opacity(0.12), in: Capsule())
    }
}

/// Lays chips out left to right and wraps to a new line when the row is full.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(width: bounds.width, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxX: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxX = max(maxX, x - spacing)
        }
        return (CGSize(width: maxX, height: y + rowHeight), origins)
    }
}
