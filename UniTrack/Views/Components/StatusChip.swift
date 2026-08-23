import SwiftUI

/// Small rounded label for a status or grade.
///
/// Kept deliberately plain — the shape carries the meaning rather than a colour,
/// so it still reads properly for anyone who can't distinguish them.
struct StatusChip: View {
    let text: String
    var systemImage: String?
    /// Optional colour for chips that carry a meaning, such as a grade or a
    /// status. Left unset the chip stays neutral.
    var tint: Color?
    var emphasised: Bool = false

    private var chipBackground: AnyShapeStyle {
        if let tint {
            return AnyShapeStyle(tint.opacity(emphasised ? 0.22 : 0.14))
        }
        return AnyShapeStyle(emphasised ? .quaternary : .quinary)
    }

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(tint ?? .primary)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(chipBackground, in: .capsule)
        .overlay {
            Capsule().strokeBorder(tint?.opacity(0.35) ?? Color.secondary.opacity(0.25),
                                   lineWidth: 0.5)
        }
    }
}
