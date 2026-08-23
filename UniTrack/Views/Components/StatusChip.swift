import SwiftUI

/// Small rounded label for a status or grade.
///
/// Kept deliberately plain — the shape carries the meaning rather than a colour,
/// so it still reads properly for anyone who can't distinguish them.
struct StatusChip: View {
    let text: String
    var systemImage: String?
    var emphasised: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(emphasised ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.quinary),
                    in: .capsule)
        .overlay {
            Capsule().strokeBorder(.separator, lineWidth: 0.5)
        }
    }
}
